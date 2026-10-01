# Ubuntu VM with Docker + Compose; the stack auto-starts on every boot.
REPO_URL = ENV.fetch("REPO_URL", "https://github.com/BloomingPlum/telco-churn-syntetic5.git")

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "telco-mlops"
  config.vm.boot_timeout = 900                    # give slow first boots more time

  config.vm.network "forwarded_port", guest: 8000, host: 8000   # FastAPI
  config.vm.network "forwarded_port", guest: 5000, host: 5000   # MLflow
  config.vm.network "forwarded_port", guest: 8888, host: 8888   # Jupyter (optional)

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "telco-mlops"
    vb.memory = 6144
    vb.cpus   = 2
    vb.gui    = false
    # send the serial console log to NUL instead of the project folder (fixes boot hangs)
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  config.vm.provision "shell", env: { "REPO_URL" => REPO_URL }, inline: <<-SHELL
    set -e
    if ! command -v docker >/dev/null; then
      curl -fsSL https://get.docker.com | sh
    fi
    usermod -aG docker vagrant
    systemctl enable --now docker

    cd /home/vagrant
    [ -d telco-churn-syntetic5 ] || sudo -u vagrant git clone "$REPO_URL" telco-churn-syntetic5
    chown -R vagrant:vagrant telco-churn-syntetic5

    if [ -f telco-churn-syntetic5/deploy/telco-churn.service ]; then
      cp telco-churn-syntetic5/deploy/telco-churn.service /etc/systemd/system/
      systemctl daemon-reload
      systemctl enable telco-churn.service
    fi
  SHELL
end