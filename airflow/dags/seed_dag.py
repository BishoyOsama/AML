import os 
from datetime import datetime
from airflow.decorators import dag

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping
from cosmos.constants import LoadMode, ExecutionMode


PROJECT_DIR = os.getenv("DBT_PROJECT_DIRECTORY", "/usr/local/airflow/dags/dbt/dbt_aml")
DBT_VENV_PATH = os.getenv("DBT_VENV", "/usr/local/airflow/dbt_venv/bin/dbt_aml")
MANIFEST_PATH  = os.getenv("DBT_MANIFEST", "/usr/local/airflow/dags/dbt/dbt_aml/target/manifest.json")

profile_config = ProfileConfig(
    profile_name="dbt_aml",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake-connection",
        profile_args={
            "database": "AML",
            "warehouse": "COMPUTE_WH",
            "schema": "default"
            }
    )
)

project_config = ProjectConfig(
    dbt_project_path = PROJECT_DIR,
    manifest_path = MANIFEST_PATH
)

execution_config = ExecutionConfig(
    execution_mode = ExecutionMode.LOCAL,
    dbt_executable_path = DBT_VENV_PATH
)

@dag(
    start_date =datetime(2022, 9, 1),
    schedule = None,
    max_active_runs = 1,
    catchup = False,
    tags = ["AML", "seed"],
    default_args = {
        "owner" : "Bishoy",
        "retries": 1,
        "retry_delay" : 300
    } 
)
def seed_dag():

    seeds = DbtTaskGroup(
        group_id = "seeds",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:seeds"]
        )
    )

    seeds

seed_dag()