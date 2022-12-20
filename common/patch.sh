
# "/audioPolicyConfiguration/modules/module/routes/route[contains(@sources, \"primary output\")]"
. $MODPATH/common/xml.sh

mytmpdir=/data/local/tmp/audaud

mkdir $mytmpdir

getbasesubmix() {
	xmlstarlet sel -t -c "/module/mixPorts" -n $1 > $mytmpdir/s_mp.xml
	xmlstarlet sel -t -c "/module/devicePorts" -n $1 > $mytmpdir/s_dp.xml
}

# d r y #

ports() {
	# 1 = 1 | 2 
	#   - index
	# 2 = file


	( xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/mixPorts" -t elem -n mixPort -v "" $2 \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]" -t attr -n name -v \
"$(xmlstarlet sel -t -v "/module/mixPorts/mixPort[$1]/@name" $mytmpdir/s_mp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]" -t attr -n role -v \
"$(xmlstarlet sel -t -v "/module/mixPorts/mixPort[$1]/@role" $mytmpdir/s_mp.xml)" \
-s "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]" -t elem -n profile \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n name -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n format -v \
"$(xmlstarlet sel -t -v "/module/mixPorts/mixPort[$1]/profile/@format" $mytmpdir/s_mp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n samplingRates -v \
"$(xmlstarlet sel -t -v "/module/mixPorts/mixPort[$1]/profile/@samplingRates" $mytmpdir/s_mp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n channelMasks -v \
"$(xmlstarlet sel -t -v "/module/mixPorts/mixPort[$1]/profile/@channelMasks" $mytmpdir/s_mp.xml)" \
) | \
	( xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/devicePorts" -t elem -n devicePort -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]" -t attr -n tagName -v \
"$(xmlstarlet sel -t -v "/module/devicePorts/devicePort[$1]/@tagName" $mytmpdir/s_dp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]" -t attr -n role -v \
"$(xmlstarlet sel -t -v "/module/devicePorts/devicePort[$1]/@role" $mytmpdir/s_dp.xml)" \
-s "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]" -t elem -n profile \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n name -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n format -v \
"$(xmlstarlet sel -t -v "/module/devicePorts/devicePort[$1]/profile/@format" $mytmpdir/s_dp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n samplingRates -v \
"$(xmlstarlet sel -t -v "/module/devicePorts/devicePort[$1]/profile/@samplingRates" $mytmpdir/s_dp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n channelMasks -v \
"$(xmlstarlet sel -t -v "/module/devicePorts/devicePort[$1]/profile/@channelMasks" $mytmpdir/s_dp.xml)" \
) > $2
}

routes() {
	xmatch "/audioPolicyConfiguration/modules/module/routes/route[contains(@sources, \"primary output\")]" $1 | while read line; do
		xmlstarlet ed --in-place -u "$line/@sources" -v "$(xmlstarlet sel -t -v "$line/@sources"),Remote Submix Out" $1
	done
}

add_input() {
	leline="/audioPolicyConfiguration/modules/module/routes/route[@sink=\"Remote Submix Out\"]/@sources"
	xmlstarlet ed --in-place -u "$leline" -v "$(xmlstarlet sel -t -v "$leline"),Built-In Mic,BT SCO Headset Mic,USB Device In,USB Headset In" $1
}

base() {
	the_file=$MODPATH/system/vendor/etc/audio_policy_configuration.xml
	xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/attachedDevices" --type elem -n item -v "Remote Submix In" $1 > $the_file
	ports 1 $the_file
	ports 2 $the_file
	
	routes $the_file

	xmlstarlet ed --in-place -u "/audioPolicyConfiguration/modules/module/routes/route[@sink=\"Remote Submix Out\"]/@sources" -v "$(xmlstarlet sel -t -v "/audioPolicyConfiguration/modules/module/routes/route[@sink=\"Remote Submix Out\"]/@sources"),primary output" $the_file

	ui_print "************************"
	ui_print "  ✓ base patches done.  "
	ui_print "           ...          "
	ui_print "  include mic input in  "
	ui_print "    recorded audio ?    "
	ui_print "------------------------"
	ui_print "    ( VOL △ = 'yes' )"
	ui_print "    ( VOL ▽ = 'no'  )"

	if chooseport 5; then
		ui_print "running micrphone patch..."
		add_input $the_file
	else
		ui_print "skipping mic patch."
	fi
}
