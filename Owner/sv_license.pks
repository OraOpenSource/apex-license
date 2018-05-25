create or replace
PACKAGE SV_LICENSE
AS
  -----------------------------------------------------------------------
  --
  --               Copyright(C) 2009 SUMNEVA
  --                  All Rights Reserved
  --
  -----------------------------------------------------------------------
  --  Application       : SUMNEVA Licensing
  --  Subsystem         : Owner side Licensing
  --  Package Name      : SUMNEVA_LICENSE
  --  Purpose           : Provide the IP owner side of the licensing equation.
  --
  -----------------------------------------------------------------------
  --  Comments:
  --
  --  SUMNEVA_LICENSE is part of the SUMNEVA Licensing Module which provides
  --  license protection for PL/SQL and APEX based products.
  --
  -----------------------------------------------------------------------
  --
  --  Naming Standards:
  --    v_<>    Variables
  --    c_<>    Constants
  --    g_<>    Package Globals
  --    ex_<>   User defined Exceptions
  --    r_<>    Records
  --    cs_<>   Cursors
  --    p_<>    Parameters for Procedures, functions and Cursors.
  --    <>_T    Types
  --    <>_O    Object Types
  --
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  --< PUBLIC TYPES AND GLOBALS >-----------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  --< PUBLIC METHODS >---------------------------------------------------
  -----------------------------------------------------------------------
  --

  ---------------------------------------------------------------------
  --< get_product_info >-----------------------------------------------
  ---------------------------------------------------------------------
  --
  -- Given a product_license_id, retrieve the information about it.
  -------------------------------------------------------------------
PROCEDURE Get_Product_Info(
    P_LICENSE_ID IN NUMBER,
    P_COMPANY_NAME OUT VARCHAR2 ,
    P_PRODUCT_GUID OUT VARCHAR2,
    P_LICENSE_TYPE OUT VARCHAR2);
---------------------------------------------------------------------
--< DECRYPT_KEY >----------------------------------------------------
---------------------------------------------------------------------
--  Purpose: Decrypts the license key.
--
---------------------------------------------------------------------
FUNCTION DECRYPT_KEY(
    P_KEY IN VARCHAR2)
  RETURN VARCHAR2;
  ---------------------------------------------------------------------
  --< decode_site_key >----------------------------------------
  -------------------------------------------------------------------
  --  Purpose         :
  --
  --  The input to this procedure is the encoded SITE KEY from a client.
  --  The return will be the decoded pieces of the system key.
  --
  ---------------------------------------------------------------------
PROCEDURE DECODE_CUSTOMER_KEY(
    P_cust_Key IN VARCHAR2,
    p_key_type OUT VARCHAR2,
    p_app_id OUT NUMBER,
    p_workspace_id OUT NUMBER,
    P_Db_Name OUT VARCHAR2,
    P_server_host OUT VARCHAR2,
    p_guid OUT VARCHAR2);

-------------------------------------------------------------------
--< DECODE_LICENSE >----------------------------------------
-------------------------------------------------------------------
--  Purpose         :
--
--  The inputs to this function ARE:
--    * A Valid License key
--
--  The output will be a the decoded license key.
--
-------------------------------------------------------------------
PROCEDURE decode_license(
    P_License_Key   IN VARCHAR2,
    p_license_type  out varchar2,
    P_Expiry_Date   OUT DATE,
    p_app_id        out varchar2,
    p_workspace_id  out varchar2,
    P_Db_Name       OUT VARCHAR2,
    P_server_host       OUT VARCHAR2,
    P_Guid          OUT VARCHAR2,
    p_company_name  OUT VARCHAR2);
   
-------------------------------------------------------------------
--< generate_license >----------------------------------------
-------------------------------------------------------------------
--  Purpose         :
--
--  The inputs to this function ARE:
--    * The LICENSE_ID  
--    * the encoded CUSTOMER KEY from a client.
--    * the license expiry date
--
--  The output will be a valid license key.
--
-------------------------------------------------------------------
FUNCTION Generate_License(
    p_license_id      NUMBER,
    p_cust_key    VARCHAR2,
    p_expiry_date     DATE )
  RETURN VARCHAR2 ;
  
-------------------------------------------------------------------
--< IS_VALID_KEY >-------------------------------------------------
-------------------------------------------------------------------
--  Purpose : Take a key string in and makes sure it can be decoded
--
--  The inputs to this function ARE:
--    * A Valid  key string
--
-------------------------------------------------------------------
PROCEDURE IS_VALID_KEY(P_KEY VARCHAR2);
END SV_LICENSE;