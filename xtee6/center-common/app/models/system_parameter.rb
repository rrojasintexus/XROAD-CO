java_import Java::ee.cyber.sdsb.common.util.CryptoUtils
java_import Java::javax.xml.crypto.dsig.DigestMethod

class SystemParameter < ActiveRecord::Base

  INSTANCE_IDENTIFIER = "instanceIdentifier"

  CENTRAL_SERVER_ADDRESS = "centralServerAddress"

  MANAGEMENT_SERVICE_PROVIDER_CLASS = "managementServiceProviderClass"

  MANAGEMENT_SERVICE_PROVIDER_CODE = "managementServiceProviderCode"

  MANAGEMENT_SERVICE_PROVIDER_SUBSYSTEM = "managementServiceProviderSubsystem"

  SECURITY_SERVER_OWNERS_GROUP =  "securityServerOwnersGroup"
  DEFAULT_SECURITY_SERVER_OWNERS_GROUP = "security-server-owners"
  DEFAULT_SECURITY_SERVER_OWNERS_GROUP_DESC = "Security server owners"

  AUTH_CERT_REG_URL = "authCertRegUrl"
  DEFAULT_AUTH_CERT_REG_URL = "https://%{centralServerAddress}:4001/managementservice/"

  CONF_SIGN_ALGO_ID = "confSignAlgoId"
  DEFAULT_CONF_SIGN_ALGO_ID = CryptoUtils::SHA512WITHRSA_ID

  CONF_HASH_ALGO_URI = "confHashAlgoUri"
  DEFAULT_CONF_HASH_ALGO_URI = DigestMethod.SHA512

  CONF_SIGN_CERT_HASH_ALGO_URI = "confSignCertHashAlgoUri"
  DEFAULT_CONF_SIGN_CERT_HASH_ALGO_URI = DigestMethod.SHA512

  OCSP_FRESHNESS_SECONDS = "ocspFreshnessSeconds"
  DEFAULT_OCSP_FRESHNESS_SECONDS = 3600

  TIME_STAMPING_INTERVAL_SECONDS = "timeStampingIntervalSeconds"
  DEFAULT_TIME_STAMPING_INTERVAL_SECONDS = 60

  CONF_EXPIRE_INTERVAL_SECONDS = "confExpireIntervalSeconds"
  DEFAULT_CONF_EXPIRE_INTERVAL_SECONDS = 600

  validates_with Validators::MaxlengthValidator

  def self.get(keyId, default_value = nil)
    value_in_db = SystemParameter.where(:key => keyId)
    if value_in_db.first
      return value_in_db.first.value
    end
    return default_value
  end

  def self.instance_identifier
    get(INSTANCE_IDENTIFIER)
  end

  def self.central_server_address
    get(CENTRAL_SERVER_ADDRESS)
  end

  def self.conf_sign_algo_id
    get(CONF_SIGN_ALGO_ID)
  end

  def self.conf_hash_algo_uri
    get(CONF_HASH_ALGO_URI)
  end

  def self.conf_sign_cert_hash_algo_uri
    get(CONF_SIGN_CERT_HASH_ALGO_URI)
  end

  def self.auth_cert_reg_url
    get(AUTH_CERT_REG_URL) % {
      :centralServerAddress => get(CENTRAL_SERVER_ADDRESS)
    }
  end

  def self.management_service_provider_class
    get(MANAGEMENT_SERVICE_PROVIDER_CLASS)
  end

  def self.management_service_provider_code
    get(MANAGEMENT_SERVICE_PROVIDER_CODE)
  end

  def self.management_service_provider_subsystem
    get(MANAGEMENT_SERVICE_PROVIDER_SUBSYSTEM)
  end

  def self.management_service_provider_id
    provider_class = management_service_provider_class
    provider_code = management_service_provider_code
    provider_subsystem = management_service_provider_subsystem

    return nil unless provider_class && provider_code

    Java::ee.cyber.sdsb.common.identifier.ClientId.create(
        instance_identifier,
        provider_class,
        provider_code,
        provider_subsystem)
  end

  def self.security_server_owners_group
    get(SECURITY_SERVER_OWNERS_GROUP)
  end

  def self.ocsp_freshness_seconds
    get(OCSP_FRESHNESS_SECONDS, DEFAULT_OCSP_FRESHNESS_SECONDS).to_i()
  end

  def self.time_stamping_interval_seconds
    get(TIME_STAMPING_INTERVAL_SECONDS,
      DEFAULT_TIME_STAMPING_INTERVAL_SECONDS).to_i()
  end

  def self.conf_expire_interval_seconds
    get(CONF_EXPIRE_INTERVAL_SECONDS,
      DEFAULT_CONF_EXPIRE_INTERVAL_SECONDS).to_i()
  end
end