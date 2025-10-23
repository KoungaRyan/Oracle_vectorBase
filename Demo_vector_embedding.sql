--- Using a Vector Embedding Model Uploaded into the Database
--- To run this script you need three files similar to the following:
--- Hugging Face all-MiniLM-L12-v2 model in ONNX format.
--- json-relational-duality-developers-guide.pdf, which is the PDF file for JSON-Relational Duality Developer's Guide
--- oracle-database-23ai-new-features-guide.pdf, which is the PDF file for Oracle Database New Features.

--- steps to load the HuggingFace sentence-transformers model 'all-MiniLM-L12-v2' into an Oracle Database 23ai

--- login as sysdba
sqlplus / as sysdba;

--- change to pluggable database FREEPDB1
SQL> alter session set container=FREEPDB1;

--- Apply grants and define the data dump directory as the path where the ONNX model was unzipped. 

--- Note, in this example, we are using the RYAN schema.

SQL> GRANT DB_DEVELOPER_ROLE, CREATE MINING MODEL TO RYAN;
SQL> CREATE OR REPLACE DIRECTORY DM_DUMP AS 'C:\all_MiniLM_L12_v2.onnx';
SQL> GRANT READ ON DIRECTORY DM_DUMP TO RYAN;
SQL> GRANT WRITE ON DIRECTORY DM_DUMP TO RYAN;
SQL> exit

--- Log into RYAN schema.
$ sqlplus ryan/ryan23@localhost:1521/FREEPDB1

--- Load the ONNX model. Optionally drop the model first if a model with the same name already exists in the database.

SQL> exec DBMS_VECTOR.DROP_ONNX_MODEL(model_name => 'ALL_MINILM_L12_V2', force => true);


BEGIN
   DBMS_VECTOR.LOAD_ONNX_MODEL(
        directory => 'DM_DUMP',
		file_name => 'all_MiniLM_L12_v2.onnx',
        model_name => 'ALL_MINILM_L12_V2',
        metadata => JSON('{"function" : "embedding", "embeddingOutput" : "embedding", "input": {"input": ["DATA"]}}'));
END;
/










