Vagrant.configure("2") do |config|

    config.vm.define "client" do |client|
    client.vm.box = "centos/7"
    client.vm.network "private_network", ip: "192.168.0.22"
    client.vm.hostname = "client"
    client.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      end

    client.vm.provision "shell", inline: <<-SHELL
       mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
       sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
       systemctl restart sshd
       timedatectl set-timezone Europe/Minsk
       yum install epel-release -y 
       yum install borgbackup  -y
       yum install ntp -y && systemctl start ntpd && systemctl enable ntpd
     SHELL

    client.vm.provision "file", source: "./script/backup.sh", destination: "/tmp/backup.sh"
    client.vm.provision "file", source: "./script/backup.service", destination: "/tmp/backup.service"
    client.vm.provision "file", source: "./script/backup.timer", destination: "/tmp/backup.timer"
    client.vm.provision "shell", inline:
 <<-SHELL
    
    mv /tmp/backup.sh /home/vagrant/backup.sh
    mv /tmp/backup.service /etc/systemd/system
    mv /tmp/backup.timer /etc/systemd/system
    
    mkdir /var/log/backup
    touch /var/log/backup/backup.log
    echo "log-file created for backup-borg"    
    sudo chmod +x /home/vagrant/backup.sh
    systemctl enable backup.timer; systemctl daemon-reload; systemctl start backup.timer
    sudo cat >> /etc/logrotate.conf <<-EOF
    /var/backup/backup.log {
    missingok
    monthly
    create 0600 root utmp
    rotate 1
    }
EOF
    sudo cat >> /etc/hosts <<EOF
192.168.0.23 backup
EOF
    SHELL


    end

    config.vm.define "backup" do |backup|

      backup.vm.box = "centos/7"
      backup.vm.network "private_network", ip: "192.168.0.23"
      backup.vm.hostname = "backup"
      backup.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      end

      backup.vm.provision "shell", inline: <<-SHELL

       mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
       sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
       systemctl restart sshd
       timedatectl set-timezone Europe/Minsk
       yum install epel-release -y; yum install borgbackup -y
       yum install ntp -y && systemctl start ntpd && systemctl enable ntpd
       sudo cat >> /etc/hosts <<EOF
192.168.0.22 client
EOF
       mkdir /var/backup
    SHELL
  end
end
