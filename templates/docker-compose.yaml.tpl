version: "3.3"
services:
  db_proxy:
    image: 'gcr.io/cloudsql-docker/gce-proxy:1.16'
    restart: always
    command: /cloud_sql_proxy --dir=/cloudsql -instances=${db_project}:${db_region}:${db_instance}=tcp:0.0.0.0:5432
    ports:
      - '127.0.0.1:5432:5432'
  web:
    depends_on:
      - "db_proxy"
    image: 'gitlab/gitlab-ee:latest'
    restart: always
    hostname: '${host_name}'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        letsencrypt['enable'] = false
        external_url 'https://${host_name}'
        letsencrypt['contact_emails'] = ['${contact_email}']
        # Disable the built-in Postgres
        postgresql['enable'] = false
        # Fill in the connection details for database.yml
        gitlab_rails['db_adapter'] = 'postgresql'
        gitlab_rails['db_encoding'] = 'utf8'
        gitlab_rails['db_host'] = 'db_proxy'
        gitlab_rails['db_port'] = 5432
        gitlab_rails['db_username'] = '${db_username}'
        gitlab_rails['db_password'] = '${db_password}'
        gitlab_rails['monitoring_whitelist'] = ['172.18.0.1/32', '127.0.0.0/8', '35.191.0.0/16', '130.211.0.0/22']
        gitlab_rails['smtp_enable'] = true
        gitlab_rails['smtp_address'] = "smtp.sendgrid.net"
        gitlab_rails['smtp_port'] = 587
        gitlab_rails['smtp_user_name'] = "${smtp_user_name}"
        gitlab_rails['smtp_password'] = "${smtp_password}"
        gitlab_rails['smtp_domain'] = "smtp.sendgrid.net"
        gitlab_rails['smtp_authentication'] = "plain"
        gitlab_rails['smtp_enable_starttls_auto'] = true
        gitlab_rails['smtp_tls'] = false
        gitlab_rails['omniauth_providers'] = [
          {
            "name" => "google_oauth2",
            "app_id" => "${google_oauth2_app_id}",
            "app_secret" => "${google_oauth2_app_secret}",
            "args" => { "access_type" => "offline", "approval_prompt" => '' }
          }
        ]
        ${custom_ruby_code}
    ports:
      - '8080:80'
      - '8443:443'
      - '2222:22'
    volumes:
      - '/opt/gitlab/home/config:/etc/gitlab'
      - '/opt/gitlab/home/logs:/var/log/gitlab'
      - '/opt/gitlab/home/data:/var/opt/gitlab'
