xmatch() {
	echo $1 
	echo $2
	echo ""
	xmlstarlet sel -t -m "$1" -m 'ancestor::*' -v 'name()' -o '/' \
-b -v "concat(name(),'[@sink=\"',@sink, '\"]')" -n $2
    #
}