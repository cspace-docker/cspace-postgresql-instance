# Prevent the PostgreSQL server from being started
# when installed (e.g. via apt-get).
#
# (Has side effect of preventing it from being stopped
# when uninstalled.)
#
# For this technique, see:
# http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/
# For the meaning of exit codes, see:
# https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt

# If no argument was supplied, exit with a success code
if [ -z $1 ];
  then
    exit 0
fi

# Otherwise, test the first argument and emit a 'not allowed' 
# exit code in the case of package names starting with 'postgresql'
case $1 in 
  # Action not allowed: exit code of 101
  postgresql* )
    exit 101 ;;
  * ) 
    exit 0 ;;
esac
