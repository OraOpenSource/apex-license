CREATE OR REPLACE
PACKAGE BODY SV_LIC_CORE
AS
  ---------------------------------------------------------------------
  --
  --               Copyright(C) 2009 SUMNEVA
  --                         All Rights Reserved
  --
  ---------------------------------------------------------------------
  --  Application       : SUMNEVA Licensing App
  --  Subsystem         : Client Side Licensing
  --  Package Name      : SV_LIC_CORE
  --  Purpose           : License Key Enforcement
  --
  --
  --  Comments:
  --
  ---------------------------------------------------------------------
  ---------------------------------------------------------------------
  --< PRIVATE TYPES AND GLOBALS >--------------------------------------
  ---------------------------------------------------------------------
  c_package VARCHAR2( 100 ) := 'SUMNEVA_SECURE'; -- Used for debug
  c_salt RAW( 2048 )        := Utl_Raw.Cast_To_Raw( SUBSTR( TO_CHAR( Sqrt(( 1967/06/23 ) ) ), 3, 38 ) );
  ---------------------------------------------------------------------
  --
  -------------------------------------------------------------------
  --< GET_SYS_STRING >----------------------------------------
  -------------------------------------------------------------------
  --
  -- PURPOSE : Creates the system string which is a combination of
  --            * DB_NAME
  --            * SERVER_HOST
  --            * PRODUCT_GUID
  -------------------------------------------------------------------
FUNCTION GET_SYS_STRING(
    P_GUID IN VARCHAR2)
  RETURN VARCHAR2
IS
  V_Sys_String VARCHAR2( 255 );
BEGIN
  --
  -- Get the items from the syscontext and create the system_key string
  -- DB_NAME:SERVER_HOST:PRODUCT_GUID
  --
   SELECT
    Sys_Context('USERENV','DB_NAME')
    || ':'
    ||Sys_Context('USERENV','SERVER_HOST')
    || ':'
    ||p_GUID
     INTO
    v_sys_string
     FROM
    Dual;
  -- Return the system string
  RETURN v_sys_string;
EXCEPTION
WHEN OTHERS THEN
  RETURN 'FAIL';
END GET_SYS_STRING;
--
-------------------------------------------------------------------
--< PAD_STRING >----------------------------------------
-------------------------------------------------------------------
--
-- PURPOSE : Pads out the string so that it can be properly encrypted
-------------------------------------------------------------------
PROCEDURE PAD_STRING(
    p_str IN OUT VARCHAR2 )
IS
  v_pad_amt NUMBER;
BEGIN
  IF LENGTH( p_str ) MOD 8 > 0 THEN
    v_pad_amt             := TRUNC( LENGTH( p_str ) / 8 ) + 1;
    p_str                 := RPAD( p_str, v_pad_amt * 8, '^' );
  END IF;
END;
---------------------------------------------------------------------
--< DECRYPT_KEY >----------------------------------------------------
---------------------------------------------------------------------
--  Purpose: Decrypts the license key.
--
---------------------------------------------------------------------
FUNCTION DECRYPT_KEY(
    P_LICENSE_KEY IN VARCHAR2)
  RETURN VARCHAR2
AS
  V_RAW_KEY RAW( 2048 );
  v_license_string VARCHAR2(32767);
BEGIN
  --
  -- Decrypt the license key
  --
  Dbms_Obfuscation_Toolkit.Desdecrypt(Input => Hextoraw( P_License_Key ), KEY => C_Salt, Decrypted_Data => V_Raw_Key );
  --
  -- Now trim off the extra junk we used to pad before.
  --
  V_LICENSE_STRING := RTRIM( UTL_RAW.CAST_TO_VARCHAR2( V_RAW_KEY ), '^' );
  --
  -- Return the final string
  --
  RETURN V_LICENSE_STRING;
EXCEPTION
WHEN OTHERS THEN
  raise_application_error( -20700, 'Unable to Decrypt License Key. Invalid License' );
END DECRYPT_KEY;
---------------------------------------------------------------------
--< PUBLIC METHODS >-------------------------------------------------
---------------------------------------------------------------------
--
---------------------------------------------------------------------
--< SAVE_LICENSE >-------------------------------------
---------------------------------------------------------------------
--  Purpose: Saves a license key to the SV_LICENSE table
--
---------------------------------------------------------------------
PROCEDURE SAVE_LICENSE(
    P_LICENSE_KEY IN VARCHAR2)
IS
BEGIN
   INSERT INTO SV_LIC_KEYS
    (license_key
    ) VALUES
    (P_LICENSE_KEY
    );
END SAVE_LICENSE;
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
  RETURN BOOLEAN
IS
  -- These are the contents of the License Key
  V_KEY_STRING   VARCHAR2(32767);
  v_license_type VARCHAR2( 32767);
  V_Expiry_Date DATE;
  v_app_id       VARCHAR2( 32767 );
  v_workspace_id VARCHAR2( 32767 );
  V_Db_Name      VARCHAR2( 32767 );
  v_server_host  VARCHAR2( 32767 );
  v_guid         VARCHAR2( 32767 );
  v_company_name VARCHAR2( 32767 );
  -- These are the comparison fields
  v_sys_key           VARCHAR2( 32767 );
  v_site_db_name      VARCHAR2( 32767 );
  v_site_server_host  VARCHAR2( 32767 );
  V_SITE_WORKSPACE_ID VARCHAR2( 32767 );
  V_SYS_ARR2 APEX_APPLICATION_GLOBAL.VC_ARR2;
  V_CUST_ARR2 APEX_APPLICATION_GLOBAL.VC_ARR2;
BEGIN
  -- DECRYPT the passed License Key
  v_KEY_STRING := DECRYPT_KEY(P_LICENSE_KEY);
  -- Break the license key into its components
  v_cust_arr2    := APEX_UTIL.STRING_TO_TABLE(v_key_string);
  v_license_type := v_cust_arr2(1);
  V_EXPIRY_DATE  := TO_DATE(v_cust_arr2(2), 'YYYYMMDD');
  v_APP_ID       := v_cust_arr2(3);
  v_workspace_id := v_cust_arr2(4);
  v_Db_Name      := v_cust_arr2(5);
  V_SERVER_HOST  := v_cust_arr2(6);
  v_Guid         := v_cust_arr2(7);
  v_company_name := v_cust_arr2(8);
  --
  -- Now we'll use the GET_SYS_STRING function to retrieve the system string for THIS system.
  --
  V_SYS_KEY  := GET_SYS_STRING(P_GUID);
  V_SYS_ARR2 := APEX_UTIL.STRING_TO_TABLE(V_SYS_KEY);
  --
  -- Break that apart into it's individual pieces
  --
  V_SITE_DB_NAME     := V_SYS_ARR2(1);
  V_SITE_SERVER_HOST := V_SYS_ARR2(2);

  -- Now match them together
  IF v_SITE_DB_NAME = v_db_name AND v_site_server_host = v_server_host THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  RETURN FALSE;
END IS_VALID_LICENSE;
-------------------------------------------------------------------
--< GEN_SYSTEM_KEY >----------------------------------------
-------------------------------------------------------------------
FUNCTION GEN_SYSTEM_KEY(
    p_GUID IN VARCHAR2)
  RETURN VARCHAR2
IS
  v_sys_str VARCHAR2( 255 );
  v_encrypted_str RAW( 2048 );
  v_return VARCHAR2( 255 );
BEGIN
  --
  -- Now get the system string
  --
  V_Sys_Str := Get_Sys_String(P_Guid);
  --
  -- If the system string didn't fail
  --
  IF V_Sys_Str != 'FAIL' THEN
    v_sys_str  := 'SITE:::'||v_sys_str;
    --
    -- Pad the string so that it will encrypt properly
    --
    Pad_String( V_Sys_Str );
    --
    -- Encrypt the string
    --
    Dbms_Obfuscation_Toolkit.Desencrypt(Input => Utl_Raw.Cast_To_Raw( V_Sys_Str ), KEY => C_Salt, Encrypted_Data => V_Encrypted_Str );
    --
    -- Now change the raw to hex
    --
    V_Return := Rawtohex( V_Encrypted_Str );
    --
    -- Return the System Key.
    --
    RETURN v_return;
  ELSE
    --
    -- If the system string generation failed, raise an error
    --
    raise_application_error( -20200, 'Unable to generate SYSTEM KEY' );
  END IF;
  -- Fall though
  RETURN NULL;
END GEN_SYSTEM_KEY;
-------------------------------------------------------------------
--< GEN_WORKSPACE_KEY >----------------------------------------
-------------------------------------------------------------------
FUNCTION GEN_WORKSPACE_KEY(
    p_GUID IN VARCHAR2,
    p_workspace_id in number)
  RETURN VARCHAR2
IS
  v_sys_str VARCHAR2( 255 );
  v_WS_Str  VARCHAR2(255);
  v_encrypted_str RAW( 2048 );
  v_return       VARCHAR2( 255 );
  v_workspace_id NUMBER;
BEGIN
  --
  -- Now get the system string
  --
  V_Sys_Str := Get_Sys_String(P_Guid);
  --
  -- If the system string didn't fail
  --
  IF V_Sys_Str != 'FAIL' THEN
 
    --
    -- Now create the APP STRING by concatenating all the items together
    -- WORKSPACE:DB_NAME:SERVER_HOST:PRODUCT_GUID
    v_ws_str := 'WORKSPACE::'||p_workspace_id||':'||v_sys_str;
    --
    -- Pad the string so that it will encrypt properly
    --
    Pad_String( v_ws_str );
    --
    -- Encrypt the string
    --
    Dbms_Obfuscation_Toolkit.Desencrypt(Input => Utl_Raw.Cast_To_Raw( V_ws_Str ), KEY => C_Salt, Encrypted_Data => V_Encrypted_Str );
    --
    -- Now change the raw to hex
    --
    V_Return := Rawtohex( V_Encrypted_Str );
    --
    -- Return the System Key.
    --
    RETURN v_return;
  ELSE
    --
    -- If the system string generation failed, raise an error
    --
    raise_application_error( -20200, 'Unable to generate SYSTEM KEY' );
  END IF;
  -- Fall though
  RETURN NULL;
END GEN_WORKSPACE_KEY;
---------------------------------------------------------------------
--< GEN_APP_KEY >-------------------------------------
---------------------------------------------------------------------
--  Purpose: Generate a Application specific key
--           The key will be passed back
--           to SUMNEVA and will be used to generate a
--           license key.
--
---------------------------------------------------------------------
FUNCTION GEN_APP_KEY(
    P_GUID   IN VARCHAR2,
    P_APP_ID IN NUMBER)
  RETURN VARCHAR2
IS
  v_workspace_id NUMBER;
  v_sys_str      VARCHAR2( 255 );
  v_app_str      VARCHAR2( 255 );
  v_encrypted_str RAW( 2048 );
  v_return VARCHAR2( 255 );
BEGIN
  --
  -- Now get the system string
  --
  V_Sys_Str := Get_Sys_String(P_Guid);
  --
  -- If the system string didn't fail
  --
  IF V_Sys_Str != 'FAIL' THEN
    --
    -- Get the WORKSPACE_ID for the specified application.
    --
    BEGIN
       SELECT
        workspace_id
         INTO
        v_workspace_id
         FROM
        apex_applications a
        WHERE
        a.application_id = P_APP_ID;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error( -20301, 'Application ID Specified, does not exist.' );
    END;
    --
    -- Now create the APP STRING by concatenating all the items together
    -- APP:WORKSPACE:DB_NAME:SERVER_HOST:PRODUCT_GUID
    --
    v_app_str := 'APP:'||P_APP_ID||':'||v_workspace_id||':'||v_sys_str;
    --
    -- Pad the string so that it will encrypt properly
    --
    Pad_String( v_app_str );
    --
    -- Encrypt the string
    --
    Dbms_Obfuscation_Toolkit.Desencrypt(Input => Utl_Raw.Cast_To_Raw( v_app_str ), KEY => C_Salt, Encrypted_Data => V_Encrypted_Str );
    --
    -- Now change the raw to hex
    --
    V_Return := Rawtohex( V_Encrypted_Str );
    --
    -- Return the System Key.
    --
    RETURN v_return;
  ELSE
    --
    -- If the system string generation failed, raise an error
    --
    raise_application_error( -20300, 'Unable to generate APP KEY' );
  END IF;
  -- Fall though
  RETURN NULL;
END GEN_APP_KEY;
---------------------------------------------------------------------
--< IS_LICENSED >----------------------------------------------------
---------------------------------------------------------------------
--  Purpose: checks to see if ther is a valid license.
--
--  RETURN:
--           Good License returns  'TRUE'
--           Bad License returns   'FALSE'
--           Trial license returns 'TRIAL'
---------------------------------------------------------------------
FUNCTION IS_LICENSED(
    p_guid         IN VARCHAR2,
    p_workspace_id IN VARCHAR2,
    P_APP_ID       IN VARCHAR2 )
  RETURN VARCHAR2
IS
  CURSOR Get_Keys
  IS
     SELECT License_Key FROM SV_LIC_KEYS;
  --
  v_license_key VARCHAR2( 255 );
  -- These are the contents of the License Key
  v_license_type VARCHAR2( 32767);
  V_Expiry_Date DATE;
  v_app_id       VARCHAR2( 32767 );
  v_workspace_id VARCHAR2( 32767 );
  V_Db_Name      VARCHAR2( 32767 );
  v_server_host  VARCHAR2( 32767 );
  v_guid         VARCHAR2( 32767 );
  v_company_name VARCHAR2( 32767 );
  -- These are the comparison fields
  v_sys_key           VARCHAR2( 32767 );
  v_site_db_name      VARCHAR2( 32767 );
  v_site_server_host  VARCHAR2( 32767 );
  V_SITE_WORKSPACE_ID VARCHAR2( 32767 );
  V_VC_ARR2 APEX_APPLICATION_GLOBAL.VC_ARR2;
BEGIN
  --
  -- First we'll use the GET_SYS_STRING function to retrieve the system string for THIS system.
  --
  V_SYS_KEY := GET_SYS_STRING(P_GUID);
  V_VC_ARR2 := APEX_UTIL.STRING_TO_TABLE(V_SYS_KEY);
  --
  -- Break that apart into it's individual pieces
  --
  V_SITE_DB_NAME     := V_VC_ARR2(1);
  V_SITE_SERVER_HOST := V_VC_ARR2(2);

  -- Now Loop through the licenses and see if we have a match.
  FOR K IN Get_Keys
  LOOP
    --
    -- Decrypt the license key
    --
    v_license_key := decrypt_key(k.license_key);
    --
    -- Now breat the sting into a vc_array
    --
    V_VC_ARR2 := APEX_UTIL.STRING_TO_TABLE(V_LICENSE_KEY);
    --
    -- Examine the first element of the license string to see if it is APP or SITE.
    --
    -- If its a SITE license We're good not matter what
    --
    v_license_type := v_vc_arr2(1);
    V_EXPIRY_DATE  := TO_DATE(V_VC_ARR2(2), 'YYYYMMDD');
    v_APP_ID       := v_vc_arr2(3);
    v_workspace_id := v_vc_arr2(4);
    v_Db_Name      := v_vc_arr2(5);
    V_SERVER_HOST  := V_VC_ARR2(6);
    v_Guid         := v_vc_arr2(7);
    v_company_name := v_vc_arr2(8);
    --
    -- Now compare to see if the license matches the DB and IP AND the license hasn't expired
    --
    IF (v_site_server_host = v_server_host) AND (V_site_Db_name = v_db_name) AND (p_guid = v_guid) AND (TRUNC(V_Expiry_Date) >= TRUNC(Sysdate)) AND ( (v_license_type = 'SITE') OR ( V_license_type = 'WORKSPACE' AND v_workspace_id = p_workspace_id ) OR ( v_license_type = 'APP' AND v_workspace_id = p_workspace_id AND v_app_id = p_app_ID) ) THEN
      RETURN 'TRUE';
    END IF;
  END LOOP;
  --
  -- If it found nothing then return FALSE
  --
  RETURN 'FALSE';
  --
EXCEPTION
WHEN OTHERS THEN
  --
  -- anything error returns a false
  --
  RETURN 'FALSE';
END IS_LICENSED;
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
    P_License_Key IN VARCHAR2,
    p_license_type OUT VARCHAR2,
    P_Expiry_Date OUT DATE,
    p_app_id OUT VARCHAR2,
    p_workspace_id OUT VARCHAR2,
    P_Db_Name OUT VARCHAR2,
    P_server_host OUT VARCHAR2,
    P_Guid OUT VARCHAR2,
    p_company_name OUT VARCHAR2)
IS
  v_raw_key raw( 2048 );
  V_LICENSE_KEY VARCHAR2( 255 );
  V_VC_ARR2 APEX_APPLICATION_GLOBAL.VC_ARR2;
BEGIN
  -- Format of the string is - LICENSE_TYPE:EXPIRY_DATE:APP_ID:WORKSPACE_ID:DBNAME:IPADDRESS:GUID:COMPANY_NAME
  --
  -- Decode the string
  --
  v_license_key := decrypt_key(p_license_key);
  --
  -- Break into the individual pieces
  --
  V_VC_ARR2 := APEX_UTIL.STRING_TO_TABLE(V_LICENSE_KEY);
  --
  p_license_type := v_vc_arr2(1);
  P_Expiry_Date  := to_date(v_vc_arr2(2), 'YYYYMMDD');
  p_app_id       := v_vc_arr2(3);
  p_workspace_id := v_vc_arr2(4);
  P_Db_Name      := v_vc_arr2(5);
  P_server_host  := v_vc_arr2(6);
  P_Guid         := v_vc_arr2(7);
  p_company_name := v_vc_arr2(8);
  --
END decode_license;
--
END SV_LIC_CORE;