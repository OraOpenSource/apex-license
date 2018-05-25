create or replace
PACKAGE BODY APEX_LICENSE
AS
  -----------------------------------------------------------------------
  --
  --  Application     : APEX Licensing
  --  Subsystem       : Owner side Licensing
  --  Package Name    : APEX_LICENSE
  --  Purpose         : Provide the IP owner side of the licensing equation.
  --
  -----------------------------------------------------------------------
  ---------------------------------------------------------------------
  --< PRIVATE TYPES AND GLOBALS >--------------------------------------
  ---------------------------------------------------------------------
  c_package VARCHAR2( 100 ) := 'APEX_LICENSE'; -- Used for debug
  c_salt Raw( 2048 )        := Utl_Raw.Cast_To_Raw( SUBSTR( TO_CHAR( Sqrt(( 1967 / 06 / 23 ) ) ), 3, 38 ) );
  -- You'll want to change the salt calculation above to something specific to your project. 
  -- This is just an example.
  ---------------------------------------------------------------------
  --< PRIVATE METHODS >------------------------------------------------
  ---------------------------------------------------------------------
  ---------------------------------------------------------------------
  --< PAD_STRING >-----------------------------------------------------
  ---------------------------------------------------------------------
  --
  -- Pads a string out to a propper length for encoding.
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
    P_KEY IN VARCHAR2)
  RETURN VARCHAR2
AS
  V_RAW_KEY RAW( 2048 );
  v_decrypted_string VARCHAR2(32767);
BEGIN
IF P_KEY IS NULL THEN
  RETURN NULL;
ELSE 
  --
  -- Decrypt the license key
  --
  Dbms_Obfuscation_Toolkit.Desdecrypt(Input => Hextoraw( P_KEY ), KEY => C_Salt, Decrypted_Data => V_Raw_Key );
  --
  -- Now trim off the extra junk we used to pad before.
  --
  V_DECRYPTED_STRING := RTRIM( UTL_RAW.CAST_TO_VARCHAR2( V_RAW_KEY ), '^' );
  --
  -- Return the final string
  --
  RETURN V_DECRYPTED_STRING;
END IF;
EXCEPTION
WHEN OTHERS THEN
  raise_application_error( -20700, 'Invalid Key. Unable to Decrypt.' );
END DECRYPT_KEY;
---------------------------------------------------------------------
--< PUBLIC METHODS >-------------------------------------------------
---------------------------------------------------------------------
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
    P_LICENSE_TYPE OUT VARCHAR2)
AS
BEGIN
   SELECT
    P.PRODUCT_GUID,
    A.ACCOUNT_NAME,
    CPL.LICENSE_TYPE
     INTO
    P_PRODUCT_GUID,
    P_COMPANY_NAME,
    P_LICENSE_TYPE
     FROM
    PRODUCTS P,
    CONTRACT_PRODUCT_LICENSE CPL,
    contracts c,
    ACCOUNTS A
    WHERE
    CPL.LICENSE_ID    = P_LICENSE_ID
    AND P.PRODUCT_ID  = CPL.PRODUCT_ID
    AND C.CONTRACT_ID = CPL.CONTRACT_ID
    AND A.ACCOUNT_ID  = C.ACCOUNT_ID;
EXCEPTION
WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR( -205010, 'Could Not Retrieve Product Info.');
END;
---------------------------------------------------------------------
--< DECODE_CUSTOMER_KEY >----------------------------------------------
---------------------------------------------------------------------
--  Purpose         :
--
--  The input to this function is the encoded SITE KEY from a client.
--  The return will be the decoded version of the system key.
--
-------------------------------------------------------------------
PROCEDURE DECODE_CUSTOMER_KEY(
    P_cust_Key IN VARCHAR2,
    p_key_type OUT VARCHAR2,
    p_app_id OUT NUMBER,
    p_workspace_id OUT NUMBER,
    P_Db_Name OUT VARCHAR2,
    P_server_host OUT VARCHAR2,
    p_guid OUT VARCHAR2)
IS
  v_raw_key raw( 2048 );
  v_cust_key VARCHAR2( 32767 );
  V_VC_ARR2 APEX_APPLICATION_GLOBAL.VC_ARR2;
BEGIN
  --
  -- Decode the key
  --
  v_cust_key := decrypt_key(p_cust_key);
  --
  -- Break into its component parts
  --
  V_VC_ARR2 := APEX_UTIL.STRING_TO_TABLE(V_cust_KEY);
  --
  --
  IF V_VC_ARR2.COUNT = 6 THEN
    P_KEY_TYPE      := V_VC_ARR2(1);
    p_app_id        := V_VC_ARR2(2);
    p_workspace_id  := V_VC_ARR2(3);
    P_DB_NAME       := V_VC_ARR2(4);
    P_server_host   := V_VC_ARR2(5);
    P_GUID          := v_vc_arr2(6);
  ELSE
    RAISE_APPLICATION_ERROR( -20501, 'Invalid Key. Does not conform to 6 field structure.');
  END IF;
END decode_customer_key;
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
    p_license_id NUMBER,
    p_cust_key   VARCHAR2,
    p_expiry_date DATE )
  RETURN VARCHAR2
IS
  V_Product_Guid     VARCHAR2( 32767 );
  v_sys_key          VARCHAR2( 32767 );
  v_key_type         VARCHAR2( 32767 );
  v_APP_ID           VARCHAR2( 32767 );
  v_WORKSPACE_ID     VARCHAR2( 32767 );
  V_Db_Name          VARCHAR2( 32767 );
  v_server_host      VARCHAR2( 32767 );
  V_Guid             VARCHAR2( 32767 );
  V_License_Key      VARCHAR2( 32767 );
  V_COMPANY_NAME     VARCHAR2( 32767 );
  V_Licensed_Account NUMBER;
  V_LICENSE_TYPE     VARCHAR2( 32767 );
  V_Expiry_Date DATE;
  --
  V_Encrypted_Str Raw( 2048 );
  --
BEGIN
  -- Lets look at what was passed in and raise errors if values are null
  IF P_License_Id IS NULL THEN
    Raise_Application_Error( -20302, 'P_LICENSE_ID CANNOT BE NULL.');
  END IF;
  --
  IF p_cust_key IS NULL THEN
    RAISE_APPLICATION_ERROR( -20300, 'P_CUSTOMER_KEY CANNOT BE NULL.' );
  END IF;
  --
  -- Set the default for the expiry date way out in the future.
  --
  IF p_expiry_date IS NULL THEN
    v_expiry_date  := to_date( '2099/12/31', 'YYYY/MM/DD' );
  ELSE
    v_expiry_date := p_expiry_date;
  END IF;
  --
  -- Decode the DES encoded string and return the decoded version
  -- The decoded string should be in the format of APP_ID:WORKSPACE_ID:DBNAME:SERVER_HOST:PRODUCT_GUID
  --
  Decode_Customer_Key( p_cust_key => p_cust_key, p_key_type => v_key_type, P_app_id => v_app_id, p_workspace_id => v_workspace_id, P_Db_Name => v_db_name, P_server_host => v_SERVER_HOST, p_guid => v_guid);
  --
  -- We need to check to see if the GUID passed on the SYSTEM key is the same as that for the product passed in.
  --
  Get_Product_Info(P_Company_Name=>V_Company_Name, P_Product_Guid=>V_Product_Guid , P_License_Id=>P_License_Id, p_license_type => v_license_type );
  --
  -- Compare the product guids.
  --
  IF (V_Product_Guid <> V_Guid) THEN
    Raise_Application_Error( -20307, 'GUID ID IN CUSTOMER KEY DID NOT MATCH GUID FOR SELECTED PRODUCT.');
  END IF;
  --
  -- Compare the License Types.
  --
  IF (v_key_type <> v_license_type) THEN
    Raise_Application_Error( -20308, 'LICENSE TYPE IN CUSTOMER KEY DID NOT MATCH LICENSE TYPE FOR SELECTED PRODUCT.');
  END IF;
  --
  --
  -- Now prepare to encode all the pieces
  --
  --
  -- 1st Assemble the parts of the license to encrypt
  --
  V_License_Key := v_license_type||':'||TO_CHAR(V_Expiry_Date, 'YYYYMMDD')||':'||v_app_id||':'||v_workspace_id||':'||V_Db_Name||':'||V_server_host||':'||V_Guid||':'||v_company_name;
  --
  -- Pad out the license Key String so we get a good hash.
  --
  Pad_String( V_License_Key);
  --
  -- Now encrypt the string.
  --
  DBMS_OBFUSCATION_TOOLKIT.DESENCRYPT(
  Input => Utl_Raw.Cast_To_Raw( V_License_Key ), KEY => c_Salt, Encrypted_Data => V_Encrypted_Str );
  --
  -- And change the raw to a hex
  --
  V_License_Key := Rawtohex( V_Encrypted_Str );
  --
  -- Now update the CONTRACT_PRODUCT_LICENSE Table with the System Key and License Key
  --
  BEGIN
     UPDATE
      CONTRACT_PRODUCT_LICENSE
    SET
      KEY_STRING     = p_cust_key,
      LICENSE_STRING = V_License_Key
      WHERE
      License_Id = P_License_Id;
  EXCEPTION
  WHEN Dup_Val_On_Index THEN
    Raise_Application_Error( -20309, 'A LICENSE FOR THIS SYSTEM KEY ALREADY EXISTS.');
  WHEN OTHERS THEN
    Raise_Application_Error( -20310, 'ERROR UPDATING LICENSE DATA.');
  END;
  --
  -- Return the generated License Key
  --
  RETURN V_License_Key;
END Generate_License;
-------------------------------------------------------------------
--< IS_VALID_KEY >-------------------------------------------------
-------------------------------------------------------------------
--  Purpose : Take a key string in and makes sure it can be decoded
--
--  The inputs to this function ARE:
--    * A Valid  key string
--
-------------------------------------------------------------------
PROCEDURE IS_VALID_KEY(
    P_KEY VARCHAR2)
IS
  V_DECODED_KEY VARCHAR2(32767);
BEGIN
  V_DECODED_KEY := DECRYPT_KEY(P_KEY);
END IS_VALID_KEY;
END APEX_LICENSE;