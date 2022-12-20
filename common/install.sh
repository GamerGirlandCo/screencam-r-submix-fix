. $MODPATH/common/patch.sh

# env

maybelist=$(/system/bin/find /system -name "audio_policy_configuration.xml" -type f -o -name "r_submix_audio_policy_configuration.xml")

if [ -z $maybelist ]; then
	ui_print "config xmls not found in system ! trying /vendor next..."
	maybelist=$(/system/bin/find /vendor -name "audio_policy_configuration.xml" -type f -o -name "r_submix_audio_policy_configuration.xml")
fi

if [ -z $maybelist ]; then
	abort "unsupported device?!?!?!!!??"
fi

r_submix=$(echo "$maybelist" | grep -i "r_submix")
apc=$(echo "$maybelist" | grep -i -v "r_submix")

if [ ! -f $MODPATH/system/vendor/etc/audio_policy_configuration.xml ]
	then
		ui_print "patched audio_policy does not exist ! copying..."
		cp $apc $MODPATH/system/vendor/etc
fi

# ui_print "copy done"

getbasesubmix $r_submix

base $apc

ui_print "....... DONE !"
