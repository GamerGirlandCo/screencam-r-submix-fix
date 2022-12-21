
# "/audioPolicyConfiguration/modules/module/routes/route[contains(@sources, \"primary output\")]"
. $MODPATH/common/xml.sh

mytmpdir=/data/local/tmp/audaud

mkdir $mytmpdir

getbasesubmix() {
	xmlstarlet sel -t -c "/module/mixPorts" -n $1 > $mytmpdir/s_mp.xml
	xmlstarlet sel -t -c "/module/devicePorts" -n $1 > $mytmpdir/s_dp.xml
	xmlstarlet sel -t -c "/module/routes" -n $1 > $mytmpdir/s_rt.xml
}

# d r y #

ports() {
	# 1 = 1 | 2 
	#   - index
	# 2 = file
  # 3 = final file

	( xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/mixPorts" -t elem -n mixPort -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]" -t attr -n name -v \
"$(xmlstarlet sel -t -v "/mixPorts/mixPort[$1]/@name" $mytmpdir/s_mp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]" -t attr -n role -v \
"$(xmlstarlet sel -t -v "/mixPorts/mixPort[$1]/@role" $mytmpdir/s_mp.xml)" \
-s "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]" -t elem -n profile \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n name -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n format -v \
"$(xmlstarlet sel -t -v "/mixPorts/mixPort[$1]/profile/@format" $mytmpdir/s_mp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n samplingRates -v \
"$(xmlstarlet sel -t -v "/mixPorts/mixPort[$1]/profile/@samplingRates" $mytmpdir/s_mp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort[count(/audioPolicyConfiguration/modules/module[1]/mixPorts/mixPort)]/profile" -t attr -n channelMasks -v \
"$(xmlstarlet sel -t -v "/mixPorts/mixPort[$1]/profile/@channelMasks" $mytmpdir/s_mp.xml)" $2 \
) | \
( xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/devicePorts" -t elem -n devicePort -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]" -t attr -n tagName -v \
"$(xmlstarlet sel -t -v "/devicePorts/devicePort[$1]/@tagName" $mytmpdir/s_dp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]" -t attr -n role -v \
"$(xmlstarlet sel -t -v "/devicePorts/devicePort[$1]/@role" $mytmpdir/s_dp.xml)" \
-s "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]" -t elem -n profile \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n name -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n format -v \
"$(xmlstarlet sel -t -v "/devicePorts/devicePort[$1]/profile/@format" $mytmpdir/s_dp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n samplingRates -v \
"$(xmlstarlet sel -t -v "/devicePorts/devicePort[$1]/profile/@samplingRates" $mytmpdir/s_dp.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort[count(/audioPolicyConfiguration/modules/module[1]/devicePorts/devicePort)]/profile" -t attr -n channelMasks -v \
"$(xmlstarlet sel -t -v "/devicePorts/devicePort[$1]/profile/@channelMasks" $mytmpdir/s_dp.xml)" \
) > $3
}

inner_routes() {
	# 1 = 1 | 2 
	#   - index
	# 2 = file
  # 3 = final file
	xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/routes" -t elem -n route -v "" \
-i "/audioPolicyConfiguration/modules/module[1]/routes/route[count(/audioPolicyConfiguration/modules/module[1]/routes/route)]" -t attr -n "type" -v "mix" \
-i "/audioPolicyConfiguration/modules/module[1]/routes/route[count(/audioPolicyConfiguration/modules/module[1]/routes/route)]" -t attr -n sink -v \
"$(xmlstarlet sel -t -v "/routes/route[$1]/@sink" $mytmpdir/s_rt.xml)" \
-i "/audioPolicyConfiguration/modules/module[1]/routes/route[count(/audioPolicyConfiguration/modules/module[1]/routes/route)]" -t attr -n sources -v \
"$(xmlstarlet sel -t -v "/routes/route[$1]/@sources" $mytmpdir/s_rt.xml)" $2 > $3
 #	cat $3 | tail -n 30
}

outer_routes() {
	bet=$(xmatch "/audioPolicyConfiguration/modules/module/routes/route[contains(@sources, \"primary output\") or (@sink = \"Telephony Tx\")]" $1)
	echo "$bet"
	actual=$1.tmp
	cp $1 $actual
	#IFS=$(printf '\n')
	for line in "$bet"; do
		nee=$(xmlstarlet sel -t -v "$line/@sources" $actual)
		echo "no" $nee
		xmlstarlet ed -u "$line/@sources" -v "$nee,Remote Submix Out" $1 > $2
		mv -T $2 $1
	done
	IFS=' '
	rm $actual
}

add_input() {
	leline="/audioPolicyConfiguration/modules/module/routes/route[@sink=\"Remote Submix Out\"]/@sources"
	cat $1 | xmlstarlet ed -u "$leline" -v "$(xmlstarlet sel -t -v "$leline" $1)" > $2
	# Built-In Mic,BT SCO Headset Mic,USB Device In,USB Headset In
}

base() {
	the_file=$MODPATH/system/vendor/etc/audio_policy_configuration.xml
	copy=$MODPATH/system/vendor/etc/audio_policy_configuration-2.xml
	cp -T $the_file $copy
	
	xmlstarlet ed -s "/audioPolicyConfiguration/modules/module[1]/attachedDevices" --type elem -n item -v "Remote Submix In" $the_file > $copy
	

	mv -T $copy $the_file

	ports 1 $the_file $copy

	mv -T $copy $the_file

	ports 2 $the_file $copy

	mv -T $copy $the_file

	outer_routes $the_file $copy

	#mv -T $copy $the_file

	inner_routes 1 $the_file $copy 

	mv -T $copy $the_file
	
	inner_routes 2 $the_file $copy 

	mv -T $copy $the_file

	xmlstarlet ed -u "/audioPolicyConfiguration/modules/module/routes/route[@sink=\"Remote Submix Out\"]/@sources" -v "$(xmlstarlet sel -t -v "/audioPolicyConfiguration/modules/module/routes/route[@sink=\"Remote Submix Out\"]/@sources" $the_file),primary output" $the_file > $copy


	mv -T $copy $the_file

	ui_print "************************"
	ui_print "  ✓ base patches done.  "
	ui_print "           ...          "
	ui_print "  include mic input in  "
	ui_print "    recorded audio ?    "
	ui_print "------------------------"
	ui_print "    ( VOL △ = 'yes' )"
	ui_print "    ( VOL ▽ = 'no'  )"

	if chooseport 5; then
		ui_print "running microphone patch..."
		add_input $the_file $copy
		mv -T $copy $the_file
	else
		ui_print "skipping mic patch."
	fi
}
