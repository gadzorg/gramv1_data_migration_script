require 'active_ldap'

ActiveLdap::Base.setup_connection host: GramV1Extractor::CONFIG["ldap_host"],
                                  base: GramV1Extractor::CONFIG["ldap_base"],
                                  port: GramV1Extractor::CONFIG["ldap_port"],
                                  bind_dn: GramV1Extractor::CONFIG["ldap_bind_dn"],
                                  password: GramV1Extractor::CONFIG["ldap_password"],
                                  logger: GramV1Extractor::LOGGER,
                                  retry_limit: 0,
                                  retry_wait: 0

module LDAP
  class Base < ActiveLdap::Base
    def prefix
      (self.dn-self.base).to_s
    end
  end
end