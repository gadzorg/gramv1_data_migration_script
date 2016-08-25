#!/usr/bin/env ruby
# encoding: utf-8

require 'logger'
require "csv"

class GramV1Extractor
  ROOT=File.dirname(__FILE__)
  LOGGER=Logger.new(STDOUT)

  OUT_FILES_PATH=File.join(ROOT,"OUT")

  require File.join(ROOT,"extra_config.rb")
  CONFIG=ExtraConfig.new(File.expand_path("config.yml",ROOT),"GRAMV1EXT")

  Dir[File.expand_path("../model/**/*.rb",__FILE__)].each {|file| require file }

  def get_all_google_apps_ids
    directory=DirectoryService.new

    api_call_count=0
    users=directory.fetch_all(items: :users) do |token|
      api_call_count+=1
      directory.list_users domain:"gadz.org", max_results: 500, page_token: token
    end
    LOGGER.info "Start retrieving Google accounts ..."
      result=users.map{|u| [u.primary_email,u.id]}.to_h
    LOGGER.info "Successfully retrieved #{result.count} Google accounts (api calls : #{api_call_count})"
    return result
  end

  def retrieve_ldap_accounts
    LOGGER.info "Start retrieving LDAP accounts ..."
    accounts=LDAP::Account.all
    LOGGER.info "Retrieved #{accounts.count} LDAP accounts"
    return accounts
  end

  def generate_uuid
    SecureRandom.uuid
  end

  def account_hash account
    # {
    #   "objectClass"=>["Compte"],
    #   "hruid"=>"alexandre.narbonne.2011",
    #   "groupe"=>["gadzarts"],
    #   "prenom"=>"Alexandre",
    #   "nom"=>"Narbonne",
    #   "idSoce"=>102096,
    #   "actif"=>true,
    #   "uid"=>["103096"],
    #   "uidNumber"=>103096,
    #   "gidNumber"=>103096,
    #   "homeDirectory"=>"/nonexistent",
    #   "alias"=>["102096", "alexandre.narbonne", "ratatosk.me211", "102096W"],
    #   "mailForwarding"=>["alexandre.narbonne@gadz.fr"],
    #   "mailAlias"=>["alexandre.narbonne@gadz.org", "alexandre.narbonne@m4am.net", "ratatosk.me211@gadz.org"],
    #   "mailAccountActive"=>["1"],
    #   "emailCompte"=>"alexandre.narbonne@gadz.org",
    #   "emailForge"=>"alexandre.narbonne@gadz.org",
    #   "dateNaissance"=>1991-04-27 00:00:00 +0200,
    #   "googleAccountUser"=>["alexandre.narbonne"],
    #   "loginValidationCheck"=>[";"],
    #   "descriptionCompte"=>"Compte Agoram",
    #   "userPassword"=>["{sha}CfeTVJmsSfV/kptwQxZBaCThLig="]
    # }

    account.attributes

  end


  def convert_to_gramv2_hash h
    {
      uuid: h["uuid"],
      hruid: h["hruid"],
      id_soce: h["idSoce"],
      enabled: h["actif"],
      password: h["userPassword"] && convert_password_from_ldap_to_gram(h["userPassword"].first),
      lastname: h["nom"],
      firstname: h["prenom"],
      email: h['emailCompte'],
      birthdate: h['dateNaissance'],
      description: h["descriptionCompte"],
      gapps_id: h["google_id"],
      aliases: h["alias"]
    }
  end

  def convert_to_soce_hash h
    {
      hruid: h["hruid"],
      uuid: h["uuid"],
    }
  end

  def convert_password_from_ldap_to_gram ldap_pass
    b64_hash=ldap_pass.gsub("{sha}","").gsub("{SHA}","")
    Base64.decode64(b64_hash).unpack("H*").first
  end

  def convert_password_to_ldap_format passwd
    #convert hexsha1 string to its binary string
    binary_value=[passwd].pack('H*')
    #base64 encoding
    b64_hash=Base64.encode64(binary_value).chomp!
    #prefix with '{SHA}'
    return "{SHA}#{b64_hash}"
  end

  def create_gramv2_csv
    file_path=File.join(OUT_FILES_PATH,"gram-#{Time.now.utc.iso8601.gsub(/\W/, '')}.csv")
    LOGGER.info "Creating GrAMv2 CSV in #{file_path}"
    CSV.open(file_path, "wb") do |csv|
      csv << convert_to_gramv2_hash(@accounts_hashs.first).keys # adds the attributes name on the first line
      @accounts_hashs.each do |hash|
        csv << convert_to_gramv2_hash(hash).values
      end
    end
    LOGGER.info "Gramv2 CSV file succefully created, you can start importing it"
  end

  def create_soce_csv
    file_path=File.join(OUT_FILES_PATH,"soce-#{Time.now.utc.iso8601.gsub(/\W/, '')}.csv")
    LOGGER.info "Creating Soce CSV in #{file_path}"
    CSV.open(file_path, "wb") do |csv|
      csv << convert_to_soce_hash(@accounts_hashs.first).keys # adds the attributes name on the first line
      @accounts_hashs.each do |hash|
        csv << convert_to_soce_hash(hash).values
      end
    end
    LOGGER.info "Soce CSV file succefully created, you can start importing it"
  end

  def update_ldap_with_uuid

    @accounts_hashs

    LOGGER.info "Start updating LDAP Account with UUID"
    LOGGER.error "Not yet implemented"
    @accounts.each do |a|
      h=@indexed_accounts_hashs[a.hruid]
      # a.uuid==h['uuid']
      # a.save
    end
    LOGGER.info "LDAP Accounts updated with UUIDS"
  end


  def process
    @accounts=retrieve_ldap_accounts
    @indexed_accounts_hashs={}
    @accounts_hashs =[]
    
    @accounts.each do |a|
      h=account_hash(a)
      @accounts_hashs << h
      @indexed_accounts_hashs[a.hruid]=h
    end

    google_account_ids=get_all_google_apps_ids

    LOGGER.info "Add data to accounts"
    @accounts_hashs.each do |a|
      LOGGER.warn "#{a["hruid"]} has an active account with no password" if a["actif"] && !a["userPassword"]

      a["uuid"]=generate_uuid
      if a["googleAccountUser"] && a["googleAccountUser"].any?
        if a["googleAccountUser"].first == ""
          a["googleAccountUser"]=nil
        else
          a["google_id"]= google_account_ids["#{a["googleAccountUser"].first}@gadz.org"]
          LOGGER.error("Can't find Google ID for #{a["hruid"]} - #{a["googleAccountUser"]}") unless a["google_id"]
        end
      end
    end
    LOGGER.info "Data added"

    create_gramv2_csv
    create_soce_csv
    update_ldap_with_uuid

  end
end
