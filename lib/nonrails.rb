# =========================================================================
# These are the tasks that are available to help with deploying web apps,
# and specifically, NON Rails applications. You can have cap give you a summary
# of them with `cap -T'.
# =========================================================================

namespace :deploy do
  desc <<-DESC
    [Overload] Deploys your project. This calls `update'. Note that \
    this will generally only work for applications that have already been deployed \
    once. For a "cold" deploy, you'll want to take a look at the `deploy:cold' \
    task, which handles the cold start specifically.
  DESC
  task :default do
    update
  end

  desc <<-DESC
    [Overload] Touches up the released code. This is called by update_code \
    after the basic deploy finishes.

    This method should be overridden to meet the requirements of your allocation.
  DESC
  task :finalize_update, :except => { :no_release => true } do
    # do nothing for non rails apps
  end

  desc <<-DESC
    [Overload] Default actions cancelled
  DESC
  task :restart, :roles => :app, :except => { :no_release => true } do
    # do nothing for non rails apps
  end

  desc <<-DESC
    [Overload] Default actions cancelled.
  DESC
  task :migrate, :roles => :db, :only => { :primary => true } do
    # do nothing for non rails apps
  end

  desc <<-DESC
    [Overload] Default actions only calls 'update'.
  DESC
  task :cold do
    update
  end

  namespace :web do
    desc <<-DESC
      Present a maintenance page to visitors. Disables your application's web \
      interface by writing a "maintenance.html" file to each web server. The \
      servers must be configured to detect the presence of this file, and if \
      it is present, always display it instead of performing the request.

      By default, the maintenance page will just say the site is down for \
      "maintenance", and will be back "shortly", but you can customize the \
      page by specifying the REASON and UNTIL environment variables:

        $ cap deploy:web:disable \\
              REASON="hardware upgrade" \\
              UNTIL="12pm Central Time"

      Further customization will require that you write your own task.
    DESC
    task :disable, :roles => :web, :except => { :no_release => true } do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }

      warn <<-EOHTACCESS

        # Please add something like this to your site's htaccess to redirect users to the maintenance page.
        # More Info: http://www.shiftcommathree.com/articles/make-your-rails-maintenance-page-respond-with-a-503

        ErrorDocument 503 /system/maintenance.html
        RewriteEngine On
        RewriteCond %{REQUEST_URI} !\.(css|gif|jpg|png)$
        RewriteCond %{DOCUMENT_ROOT}/system/maintenance.html -f
        RewriteCond %{SCRIPT_FILENAME} !maintenance.html
        RewriteRule ^.*$  -  [redirect=503,last]
      EOHTACCESS

      reason = ENV['REASON']
      deadline = ENV['UNTIL']

      template = File.read(File.join(File.dirname(__FILE__), "templates", "maintenance.rhtml"))
      result = ERB.new(template).result(binding)

      put result, "#{shared_path}/system/maintenance.html", :mode => 0644
    end

    desc <<-DESC
      Makes the application web-accessible again. Removes the \
      "maintenance.html" page generated by deploy:web:disable, which (if your \
      web servers are configured correctly) will make your application \
      web-accessible again.
    DESC
    task :enable, :roles => :web, :except => { :no_release => true } do
      run "rm #{shared_path}/system/maintenance.html"
    end
  end
end