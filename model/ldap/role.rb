module LDAP
  class LDAP::Role < LDAP::Base 
    ldap_mapping :dn_attribute => 'roleName',
                 :classes => ['top','roleSI'],
                 :prefix => 'ou=comptes',
                 :scope => :sub

  end
end