create or replace
PACKAGE APEX_LIC_CORE
AS

  ---------------------------------------------------------------------
  --  Application       :  Licensing App
  --  Subsystem         : Client Side Licensing
  --  Package Name      : APEX_LIC_CORE
  --  Purpose           : License Key Enforcement
  --
  -----------------------------------------------------------------------
  --  Comments:
  --
  --  APEX_LIC_CORE is part of the  Licensing Module which provides
  --  license protection for PL/SQL and APEX based products.
  --
  -----------------------------------------------------------------------
  --
  --  Naming Standards:
  --    v_<>    Variables
  --    c_<>   Constants
  --    g_<>   Package Globals
  --    ex_<>   User defined Exceptions
  --    r_<>   Records
  --    cs_<>  Cursors
  --    p_<>    Parameters for Procedures, functions and Cursors.
  --    <>_T   Types
  --    <>_O   Object Types
  --
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  --< PUBLIC TYPES AND GLOBALS >-----------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  --< PUBLIC METHODS >---------------------------------------------------
  -----------------------------------------------------------------------
  ---------------------------------------------------------------------
  --< SAVE_LICENSE >-------------------------------------
  ---------------------------------------------------------------------
  --  Purpose: Saves a license key to the SV_LICENSE table
  --
  ---------------------------------------------------------------------
PROCEDURE SAVE_LICENSE(
    P_LICENSE_KEY IN VARCHAR2);
  ---------------------------------------------------------------------
  --< IS_VALID_LICENSE >-------------------------------------
  ---------------------------------------------------------------------
  --  Purpose: Takes a license key and makes sure it's VALID
  --
  ---------------------------------------------------------------------
FUNCTION IS_VALID_LICENSE
  (
    P_GUID        IN VARCHAR2,
    P_LICENSE_KEY IN VARCHAR2
  )
  RETURN BOOLEAN;
  ---------------------------------------------------------------------
  --< GEN_SYSTEM_KEY >-------------------------------------
  ---------------------------------------------------------------------
  --  Purpose: Generate a system key specific to the system on which
  --           the software is installed. The key will be passed back
  --           to OWNER and will be used to generate a
  --           license key.
  --
  ---------------------------------------------------------------------
FUNCTION GEN_SYSTEM_KEY(
    P_GUID IN VARCHAR2)
  RETURN VARCHAR2;
-------------------------------------------------------------------
--< GEN_WORKSPACE_KEY >----------------------------------------
-------------------------------------------------------------------
FUNCTION GEN_WORKSPACE_KEY(
    p_GUID IN VARCHAR2,
    p_workspace_id in number)
  RETURN VARCHAR2;
  ---------------------------------------------------------------------
  --< GEN_APP_KEY >-------------------------------------
  ---------------------------------------------------------------------
  --  Purpose: Generate a Application specific key
  --           The key will be passed back
  --           to OWNER and will be used to generate a
  --           license key.
  --
  ---------------------------------------------------------------------
FUNCTION GEN_APP_KEY(
    P_GUID IN VARCHAR2,
    P_APP_ID IN NUMBER)
  RETURN VARCHAR2;
  ---------------------------------------------------------------------
  --< IS_LICENSED >----------------------------------------------------
  ---------------------------------------------------------------------
  --  Purpose: Checks to see if the product is licensed for the given App.
  --
  --
  ---------------------------------------------------------------------
FUNCTION IS_LICENSED(
    p_guid         IN VARCHAR2,
    p_workspace_id IN VARCHAR2,
    P_APP_ID       IN VARCHAR2 )
  RETURN VARCHAR2;
-------------------------------------------------------------------
--< DECRYPT_KEY >----------------------------------------
-------------------------------------------------------------------
--  Purpose         :
--
--  The inputs to this function ARE:
--    * A Valid License key
--
--  The output will be a the decoded license key in a single string
--
------------------------------------------------------------------- 
FUNCTION DECRYPT_KEY(
    P_LICENSE_KEY IN VARCHAR2)
  RETURN VARCHAR2;
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
    P_server_host   OUT VARCHAR2,
    P_Guid          OUT VARCHAR2,
    p_company_name  OUT VARCHAR2);
END APEX_LIC_CORE;