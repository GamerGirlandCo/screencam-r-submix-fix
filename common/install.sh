. $MODPATH/common/patch.sh

export maybelist=$(find /system -name "audio_policy_configuration.xml" -type f -o -name "r_submix_audio_policy_configuration.xml")

if [ -z $maybelist ] then
	ui_print "config xmls not found in system ! trying /vendor next..."
	export maybelist=$(find /vendor -name "audio_policy_configuration.xml" -type f -o -name "r_submix_audio_policy_configuration.xml")
done

if [ -z $maybelist ] then
	abort "unsupported device?!?!?!!!??"
done

r_submix=$(echo $maybelist | grep -i "r_submix")
apc=$(echo $maybelist | grep -i -v "r_submix")

if [ ! -f /data/local/tmp/audio_policy_configuration.xml ]
	then
		ui_print "original audio_policy backup does not exist ! copying..."
		cp $apc /data/local/tmp
fi

getbasesubmix $r_submix

base $apc

ui_print "....... DONE !"
