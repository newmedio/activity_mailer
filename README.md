# Activity-Based Templated Emailer Utility

This gem provides a layer of abstraction for Mandrill templated emails.
You may wonder, "why a layer of abstraction?"

Let's say I am using Mandrill to send emails.
Mandrill has a mechanism for allowing users to manage email templates. 
This is great, but we need a mechanism to make sure the templated emails connect back to the service, *especially* when multiple languages are involved.

Therefore, this gem instantiates a set of standard conventions, and then uses them to pick out and use Mandrill templates at the right time.

## Installation and Configuration

To install, just stick it in your Gemfile

```
gem 'activity-mailer', :require => "activity_mailer"
```

The best way to configure it is to create a shared connection in your initializers.  
Something like this:

```
require "mandrill" # Needed to get the connection
mconn = Mandrill::API.new("MANDRILL_API_KEY")
service_name = "my-service-name" 
conn = ActivityMailer.new(mconn, service_name)
conn.supported_languages = ["en", "fr", "es"]
```

## Getting Templates Ready

The first thing to do when you install it is to run the following from the Rails console:

```
ActivityMailer.shared_connection.create_default_template!("noreply@mydomain.com", "My From Name", "Default Subject")
```

This will create a default template in your mail system for all of your supported languages.
After this, you should customize the templates how you like.

Then, when you are ready to add in a new type of email (i.e., a receipt email or something), you can generate it as follows:

```
ActivityMailer.shared_connection.register_template!("receipt")
```

This copies the default template in each language to a new template that can be further customized.

Then, to use the templates, just do the following:

```
recipients = [
	{
		"type" => "to", 
		"email" => "whoever@example.com", 
		"name" => "Whoever"
	}
]

ActivityMailer.shared_connection.deliver_email!(
	"receipt", 
	"en", 
	{ "to" => recipients }, 
	{ "key" => "val", "key2" => "val2" }
)
```

If a given language is not available, it uses default_language (defaults to English) as the default.  If it can't find a default langauge then it picks any language.  Failing that, it throws an error.
