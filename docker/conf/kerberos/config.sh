#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=NODE.DC1.CONSUL}
: ${DOMAIN_REALM:=node.dc1.consul}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}
: ${SEARCH_DOMAINS:=search.consul node.dc1.consul}

fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search $SEARCH_DOMAINS
EOF
}

fix_hostname() {
  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

create_config() {
  : ${KDC_ADDRESS:=$(hostname -f)}

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 1h
 renew_lifetime = 1h
 forwardable = true

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
 }

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM
EOF
}

create_db() {
  /usr/sbin/kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

start_kdc() {
  mkdir -p /var/log/kerberos

  /etc/rc.d/init.d/krb5kdc start
  /etc/rc.d/init.d/kadmin start

  chkconfig krb5kdc on
  chkconfig kadmin on
}

restart_kdc() {
  /etc/rc.d/init.d/krb5kdc restart
  /etc/rc.d/init.d/kadmin restart
}

create_admin_user() {
  kadmin.local -q "addprinc -pw $KERB_ADMIN_PASS $KERB_ADMIN_USER/admin"
  echo "*/admin@$REALM *" > /var/kerberos/krb5kdc/kadm5.acl
}

create_keytabs() {
    rm /etc/kerberos/*.keytab

    kadmin.local -q "addprinc -randkey zookeeper/sp-zk.sptest_deps_sptest@${REALM}"
    kadmin.local -q "addprinc -randkey zkclient@${REALM}"
    kadmin.local -q "addprinc -randkey kafka/sp-kafka.sptest_deps_sptest@${REALM}"
    kadmin.local -q "addprinc -randkey clickhouse/sp-ch-1.sptest_deps_sptest@${REALM}"
    kadmin.local -q "addprinc -randkey clickhouse/sp-ch-2.sptest_deps_sptest@${REALM}"

    kadmin.local -q "ktadd -norandkey -k /etc/kerberos/zookeeper_sp-zk.keytab zookeeper/sp-zk.sptest_deps_sptest@${REALM}"
    kadmin.local -q "ktadd -norandkey -k /etc/kerberos/zkclient.keytab zkclient@${REALM}"
    kadmin.local -q "ktadd -norandkey -k /etc/kerberos/kafka_sp-kafka.keytab kafka/sp-kafka.sptest_deps_sptest@${REALM}"
    kadmin.local -q "ktadd -norandkey -k /etc/kerberos/clickhouse_sp-ch-1.keytab clickhouse/sp-ch-1.sptest_deps_sptest@${REALM}"
    kadmin.local -q "ktadd -norandkey -k /etc/kerberos/clickhouse_sp-ch-2.keytab clickhouse/sp-ch-2.sptest_deps_sptest@${REALM}"

    chmod g+r /etc/kerberos/clickhouse_sp-ch-1.keytab
    chmod g+r /etc/kerberos/clickhouse_sp-ch-2.keytab

    cp /etc/krb5.conf /etc/kerberos/
}

main() {
  fix_nameserver
  fix_hostname

  if [ ! -f /kerberos_initialized ]; then
    create_config
    create_db
    create_admin_user
    start_kdc

    touch /kerberos_initialized
  fi

  if [ ! -f /var/kerberos/krb5kdc/principal ]; then
    while true; do sleep 1000; done
  else
    start_kdc
    create_keytabs
    tail -F /var/log/kerberos/krb5kdc.log
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"