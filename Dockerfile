FROM ubuntu:16.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y  software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt-get clean

    #Mule ESB CE version 3.8.1
ENV MULE_VERSION=3.8.1 \
    # Jolokia JMX-over-HTTP Mule agent version.
    JOLOKIA_VERSION=1.3.7 \
    # Name of file which the Mule ESB distribution will be downloaded to.
    MULE_ARCHIVE="mule-standalone.tar.gz" \
    # Parent directory in which the Mule installation directory will be located.
    INSTALLATION_PARENT=/opt \
    # Name of Mule installation directory.
    INSTALLATION_DIRECTORY_NAME=mule-standalone \
    # User and group that the Mule ESB instance will be run as, in order not to run as root.
    # Note that the name of this property must match the property name used in the Mule ESB startup script.
    RUN_AS_USER=mule \
    # Set this environment variable to true to set timezone on container start.
    SET_CONTAINER_TIMEZONE=true \
    # Default container timezone.
    CONTAINER_TIMEZONE=Europe/Stockholm
ENV MULE_DOWNLOAD_URL=https://repository-master.mulesoft.org/nexus/content/repositories/releases/org/mule/distributions/mule-standalone/${MULE_VERSION}/mule-standalone-${MULE_VERSION}.tar.gz \
    MULE_HOME="$INSTALLATION_PARENT/$INSTALLATION_DIRECTORY_NAME"

    # Add user (and group) which will run Mule ESB in the container.
RUN groupadd -f ${RUN_AS_USER} && \
    useradd --system --home /home/${RUN_AS_USER} -g ${RUN_AS_USER} ${RUN_AS_USER} && \
    # Updates for Debian.
    apt-get update && \
    apt-get dist-upgrade -y && \
    # Install NTP for time synchronization, wget to download stuff and
    # procps since Mule uses the ps command and it is not installed per default.
    apt-get install -y ntp wget procps && \
    # Clean up.
    apt-get autoclean && apt-get --purge -y autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \

    # Download and unpack Mule ESB.
    cd ${INSTALLATION_PARENT} && \
    wget ${MULE_DOWNLOAD_URL} && \
    tar xvzf mule-standalone-*.tar.gz && \
    rm mule-standalone-*.tar.gz && \
    mv mule-standalone-* ${INSTALLATION_DIRECTORY_NAME} && \
    # Download the Jolokia JAR-file to the correct location in the Mule installation.
    wget -O ${MULE_HOME}/lib/opt/jolokia-mule-agent.jar http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-mule/${JOLOKIA_VERSION}/jolokia-mule-${JOLOKIA_VERSION}-agent.jar

# Copy the script used to launch Mule ESB when a container is started.
COPY ./scripts/start-mule.sh ${INSTALLATION_PARENT}/
# Copy configuration files to Mule ESB configuration directory.
COPY ./conf/*.* ${MULE_HOME}/conf/
# Add the Jolokia enabler Mule application.
ADD ./apps/jolokia-enabler ${MULE_HOME}/apps/jolokia-enabler

    # Make the start-script executable.
RUN chmod +x ${INSTALLATION_PARENT}/start-mule.sh && \
    # Set the owner of all Mule-related files to the user which will be used to run Mule.
    chown -R ${RUN_AS_USER}:${RUN_AS_USER} ${MULE_HOME} && \
    # Restrict access to the JMX passwords file, or Mule ESB will fail to startup.
    chmod 600 ${MULE_HOME}/conf/jmx.password

    # ssh install
# script de inicialização dos serviços
COPY ./scripts/all_comands.sh /usr/local/bin/all_comands.sh
COPY ./scripts/start_services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start_services.sh
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'mule:mule' | chpasswd
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN sed 's/invoke-rc\.d/service/g' -i /etc/network/if-up.d/openssh-server
RUN systemctl enable sshd; exit 0
#RUN sed 's/Restart=on-failure/Restart=always\nRestartSec=30/g' -i /etc/systemd/system/sshd.service
#RUN sed 's/start on runlevel \[2345\]/start on filesystem and net-device-up IFACE!=lo/g' -i /etc/init/ssh.conf
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


WORKDIR ${MULE_HOME}
#ssh Port
EXPOSE 22
# Default http port
EXPOSE 8081
# JMX port.
EXPOSE 1099
# Jolokia port.
EXPOSE 8899

# Default when starting the container is to start Mule ESB.
#CMD ["/bin/bash" , "/usr/local/bin/start_services.sh", "dsv", "/opt/start-mule.sh"]
# default command
CMD ["/usr/local/bin/all_comands.sh", "dsv"]


# Define mount points.
VOLUME ["${MULE_HOME}/logs", "${MULE_HOME}/conf", "${MULE_HOME}/apps", "${MULE_HOME}/domains"]