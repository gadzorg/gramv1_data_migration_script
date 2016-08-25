module LDAP
  class Account < LDAP::Base 
    ldap_mapping :dn_attribute => 'hruid',
                 :classes => ['Compte'],
                 :prefix => 'ou=comptes',
                 :scope => :one

    #belongs_to :groups, :class_name => 'LDAP::Group', :many => 'memberUid', :primary_key => 'dn'

    before_destroy :clear_associations

    def clear_associations
      self.groups.delete(self.groups)
    end

    def roles(params={})
      params.merge!(prefix: self.prefix)
      LDAP::Role.find(params)
    end


    def add_role(role_name, application_filter="/.*/")
      dn="roleName=#{role_name},#{self.dn}"
      role=LDAP::Role.new(dn)
      role.applicationFilter=application_filter
      role.ineritUser=true
      role
    end

    def assign_attributes_from_gram(gram_data)
      uid_number= gram_data.id_soce+1000
      self.assign_attributes({
        :uuid           => gram_data.uuid,
        :idSoce         => gram_data.id_soce,
        :hruid          => gram_data.hruid,
        :prenom         => gram_data.firstname,
        :nom            => gram_data.lastname,
        :actif          => gram_data.enabled,
        :gidNumber      => uid_number,
        :uid            => uid_number.to_s,
        :uidNumber      => uid_number,
        :emailCompte    => gram_data.email,
        :emailForge     => gram_data.email,
        :userPassword   => self.class.convert_password_to_ldap_format(gram_data.password),
        :alias          => gram_data.alias.map{|a| a.name}
      })
      self.dn="hruid=#{gram_data.hruid},ou=comptes,ou=gram,dc=gadz,dc=org"
      self
    end

    def self.find_or_build_by_uuid(uuid)
      find(attribute: "uuid", value: uuid) || LDAP::Account.new(default_values)
    end

    def self.default_values
      {
        descriptionCompte: "Created by LdapDaemon at #{DateTime.now}",
        homeDirectory: '/nonexistant',
        loginValidationCheck: "CGU=;"      
      }
    end

    #Take a sha1 hex string in input
    #ex : 5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8
    #returns a base64 encoded value prefixed with {SHA}
    def self.convert_password_to_ldap_format passwd
      #convert hexsha1 string to its binary string
      binary_value=[passwd].pack('H*')
      #base64 encoding
      b64_hash=Base64.encode64(binary_value).chomp!
      #prefix with '{SHA}'
      return "{SHA}#{b64_hash}"
    end
  end
end