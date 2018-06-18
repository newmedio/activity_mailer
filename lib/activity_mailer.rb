# This class will do the following:
# a) Look up the "best match" template (i.e., if a language-specific version isn't found, use English)
# b) Send a message using the "best match" template
#
# Uses the Mandrill API, but largely masks it
#
# Template registration depends on an initially-created template in Mandrill with the tags service-subscription, activity-default, lang-en

class ActivityMailer
	attr_accessor :mandrill_connection
	attr_accessor :default_language
	attr_accessor :supported_languages # This is only really used for default template creation
	attr_accessor :mandrill_ip_pool

	def initialize(mandrill_conn, service_name)
		@mandrill_connection = mandrill_conn
		@service_name = service_name
		@service_label = "service-#{service_name}"
		@default_language = "en"
		@supported_languages = [@default_language]
		@mandrill_ip_pool = nil
	end

	def self.shared_connection=(val)
		@@shared_connection = val
	end

	def self.shared_connection
		@@shared_connection
	end

	# This should only be done once
	def create_default_template!(from_addr, from_name, subject)

		@supported_languages.each do |lang|
			name = name_from_labels("default", lang)
			templ = @mandrill_connection.templates.add(name, from_addr, from_name, subject, "<div>FIXME</div>", "FIXME", true, [@service_label, "activity-default", "lang-#{lang}"])
		end
	end

	def name_from_labels(activity, lang)
		"#{@service_name.underscore.titleize}/#{activity.underscore.titleize}/#{lang.underscore}"
	end

	# Registers a new type of template
	def register_template!(system_name)
		default_templates = @mandrill_connection.templates.list(@service_label).select{|templ| 
			templ["labels"].include?("activity-default") && templ["published_at"] != nil
		}
		default_templates.each do |templ|
			lang = begin
				templ["labels"].select{|x| x.include?("lang-")}.first.split("-")[1]
			rescue
				if defined? Rails
					Rails.logger.warn("Bad language for template")
				end
				nil
			end
			next if lang.nil?

			new_templ_name = name_from_labels(system_name, lang)
			new_templ = @mandrill_connection.templates.add(new_templ_name, templ["publish_from_email"], templ["publish_from_name"], templ["publish_subject"], templ["publish_code"], templ["publish_text"], true, [@service_label, "activity-#{system_name}", "lang-#{lang}"])
		end
	end

	def templates_for(system_name, language = nil, best = true)
		language = default_language if language.nil?
		possible_templates = @mandrill_connection.templates.list(@service_label).select{|templ| 
			# must be of the right activity
			templ["labels"].include?("activity-#{system_name}") && 
			# if it is unpublished, don't include it
			templ["published_at"] != nil
		}

		# Do I have one for my language?
		lang_templates = possible_templates.select{|templ| templ["labels"].include?("lang-#{language}")}
	
		# No? Then grab the one for the default language
		if lang_templates.empty?
			lang_templates = possible_templates.select{|templ| templ["labels"].include?("lang-#{default_language}")}
		end

		# Still none? Well, just send them all
		if lang_templates.empty?
			lang_templates = possible_templates
		end

		return lang_templates
	end

	# NOTE - this can throw exceptions - should rescue them
	def deliver_email!(activity, lang, message_info, data = {})
		templ_list = templates_for(activity, lang)
		raise "No template found" if templ_list.empty?

		# Log error if too many templates
		if templ_list.size > 1
			if(defined? Rails)
				Rails.logger.warn("Too many templates for #{activity}/#{lang}!") 
			end
		end

		templ = templ_list.first

		mandrill_data = []
		data.each do |k, v|
			mandrill_data.push({:name => k, :content => v})
		end
		
		@mandrill_connection.messages.send_template(templ["name"], data, message_info, false, @mandrill_ip_pool)
	end
end
