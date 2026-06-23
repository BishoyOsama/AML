import os 
from datetime import datetime
from airflow.decorators import dag

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping
from cosmos.constants import LoadMode, ExecutionMode


PROJECT_DIR = "/usr/local/airflow/dags/dbt/dbt_aml"
DBT_VENV_PATH = "/usr/local/airflow/dbt_venv/bin/dbt_aml"
MANIFEST_PATH  = "/usr/local/airflow/dags/dbt/dbt_aml/target/manifest.json"

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
    schedule = "@daily",
    max_active_runs = 1,
    catchup = False,
    tags = ["AML", "Transform", "Full-refresh", "Incremental"],
    default_args = {
        "owner" : "Bishoy",
        "retries": 1,
        "retry_delay" : 300
    } 
)
def aml_dag():

    """ seeds = DbtTaskGroup(
        group_id = "seeds",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:seeds"]
        ),
        operator_args = {
            "full_refresh": True
        }
    ) """

    silver_full_refresh = DbtTaskGroup(
        group_id = "silver_full_refresh",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = [
                "path:models/silver"
            ],
            exclude = ["transactions"]
        ), 
        operator_args = {
            "full_refresh": True
        }
    )

    silver_incremental = DbtTaskGroup(
        group_id = "silver_incremental",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:models/silver"],
            exclude = ["patterns", "accounts"]
        ),
        operator_args = {
            "vars": "{\"run_date\": \"{{ ds }}\" }"
        }
    )

    gold_dims = DbtTaskGroup(
        group_id = "gold_dims",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:models/gold"],
            exclude = ["fact_transactions"]
        ),
        operator_args = {
            "full_refresh": True
        }
    )

    gold_fact = DbtTaskGroup(
        group_id = "gold_fact",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:models/gold"],
            exclude = [
                "dim_bank_accounts",
                "dim_banks",
                "dim_date",
                "dim_date_no_timestamp",
                "dim_entity",
                "dim_patterns"
            ]
        ),
        operator_args = {
            "vars": "{ \"run_date\": \"{{ ds }}\" }"
        }
    )

    marts_incremental = DbtTaskGroup(
        group_id = "marts_incremental",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:models/marts"],
            exclude = [
                "bank_flow_matrix",
                "conformed_dim_bank_accounts",
                "conformed_dim_banks",
                "conformed_dim_currency",
                "conformed_dim_date_no_timestamp",
                "conformed_dim_payment_formats",
                "patterns_summary"
                ]
        ),
        operator_args = {
            "vars": "{ \"run_date\": \"{{ ds }}\" }"
        }
    )

    marts_views = DbtTaskGroup(
        group_id = "marts_views",
        project_config = project_config,
        profile_config = profile_config,
        execution_config = execution_config,
        render_config = RenderConfig(
            load_method = LoadMode.DBT_MANIFEST,
            select = ["path:models/marts"],
            exclude = [
                "account_activity_summary",
                "account_currency_summary",
                "hourly_transaction_patterns"
                ]
        )
    )

    silver_full_refresh >> silver_incremental >> gold_dims >> gold_fact >> marts_incremental >> marts_views

""" dbt_snowflake_dag= DbtDag(
    project_config=ProjectConfig("/usr/local/airflow/dags/dbt/dbt_aml"),
    operator_args={"install_deps": True},
    profile_config=profile_config,
    execution_config=ExecutionConfig(dbt_executable_path=f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt"),
    schedule="@daily",
    start_date=datetime(2022, 9, 1),
    catchup=False,
    dag_id= "dbt_dag"
) """

aml_dag()