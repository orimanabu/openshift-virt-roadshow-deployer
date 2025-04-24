#!/bin/bash

if [ $# -lt 1 ]; then
	echo "$0 subcmd"
	exit 1
fi
subcmd=$1; shift

user_password=secret

case ${subcmd} in
setup)
	$0 setup-python
	$0 setup-ansible
	;;
setup-python)
	python3 -m venv .venv
	./.venv/bin/python3 -m pip install --upgrade pip
	./.venv/bin/python3 -m pip install -r requirements.txt
	;;
setup-ansible)
	./.venv/bin/ansible-galaxy collection install -r requirements.yml
	;;
create-htpasswd)
	htpasswd -c -B -b htpasswd_users.txt user0 jyxb20mTCxQOQ8D9
	htpasswd -B -b htpasswd_users.txt user1 ${user_password}
	htpasswd -B -b htpasswd_users.txt user2 ${user_password}
	htpasswd -B -b htpasswd_users.txt user3 ${user_password}
	htpasswd -B -b htpasswd_users.txt user4 ${user_password}
	htpasswd -B -b htpasswd_users.txt user5 ${user_password}
	htpasswd -B -b htpasswd_users.txt user6 ${user_password}
	htpasswd -B -b htpasswd_users.txt user7 ${user_password}
	htpasswd -B -b htpasswd_users.txt user8 ${user_password}
	htpasswd -B -b htpasswd_users.txt user9 ${user_password}
	;;

create-user*)
	token=$(oc whoami -t)
	rc=$?
	if [ x"$rc" != x"0" ]; then
		exit 1
	fi
	echo "token: ${token}"

	oc create secret generic virt-handson --from-file=htpasswd=htpasswd_users.txt -n openshift-config
	sleep 1

	result=$(oc get oauth/cluster -o json | jq '.spec.identityProviders')

	if [ "$result" = "null" ]; then
		oc patch oauth/cluster --type json --patch '
[{
  "op": "add",
  "path": "/spec/identityProviders",
  "value": []
}]'
	fi

	oc patch oauth/cluster --type json --patch '
[{
  "op": "add",
  "path": "/spec/identityProviders/-",
  "value": {
    name: "virt_handson",
    mappingMethod: "claim",
    type: "HTPasswd",
    htpasswd: {
      fileData: {
        name: "virt-handson"
      }
    }
  }
}]'
	;;
run|run-1)
	./.venv/bin/ansible-playbook -e username=user1 -e password=${user_password} site.yml $*
	;;
run-all)
	./.venv/bin/ansible-playbook -e username=user1 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user2 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user3 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user4 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user5 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user6 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user7 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user8 -e password=${user_password} site.yml $*
	./.venv/bin/ansible-playbook -e username=user9 -e password=${user_password} site.yml $*
	;;
localization|l10n)
	curl -sSL https://gist.githubusercontent.com/KaitoInaba/1594964e92bb1c0ded7609acdb6ed2f6/raw/cd4a204cb929b2dcb9a75916ab43ceb42c1901d0/translation.sh | bash
	;;
*)
	echo "unknown subcmd: ${subcmd}"
	exit 1
	;;
esac
