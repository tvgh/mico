# @author FlashSoft
# == �Զ������� ==============================================

# ����nodered�Ľ��յ�ַ
nodered_url="http://192.168.1.22:1880"

# �趨asr���ش�,�����߷ָ�ÿ�����ش�
asr_keywords=""

# �趨res���ش�,�����߷ָ�ÿ�����ش�
res_keywords=""

# ���ô�nodered�������شʵļ��,��λ��
# 0��������,һֱʹ�ñ������ش�
# ����0�����,��������趨��nodered_urlȥ��ȡ���ش�,�����Ǳ��ص����ش�
keywords_update_timeout=10

# NodeRed�˺�����
#nodered_auth=":"
nodered_auth="root:vvpivcol"  #bytt
# С��asr��־��ַ
asr_file="/tmp/mipns/mibrain/mibrain_asr.log"
# С��res��־��ַ
res_file="/tmp/mipns/mibrain/mibrain_response.log"
# == /�Զ������� ==============================================
 
# ������ܴ��ڵ�һ���ļ�����������
touch ${asr_file}
touch ${res_file} 
res_md5=""
last_time="0"

echo "==============================================================="
echo ""
echo "      NodeRed�����ַ: ${nodered_url}"
echo "      NodeRed�˺�����: `[ "${nodered_auth}" == ":" ] && echo "������" || echo "������"`     "
echo "            asr���ش�: `[ "${asr_keywords}" == "" ] && echo "�����ش�" || echo ${asr_keywords}`    "
echo "            res���ش�: `[ "${res_keywords}" == "" ] && echo "�����ش�" || echo ${res_keywords}`    "
echo "       ���شʸ���Ƶ��: `[ "${keywords_update_timeout}" == "0" ] && echo "������" || echo ${keywords_update_timeout}`    "
echo ""
echo "==============================================================="


echo "��ʼ��֤NodeRed�����Ƿ�ͨ��"
echo ""
header=`curl --insecure �Cconnect-timeout 2 -m 2 -sI -u "${nodered_auth}" ${nodered_url}`
if [ -z "`echo ${header}`" ];then
  echo "��֤��ͨ��: NodeRed��ַ��ͨ"
  exit
else
  if [ -z "`echo "${header}" |grep 'HTTP/'|awk '($2==200){print 1}'`" ];then
    echo "��֤��ͨ��: NodeRed�ӿ�״ֵ̬��200 [�������벻��ȷ]"
    exit
  else
    echo "��֤ͨ��"
  fi
fi
 
while true;do
  # ����md5ֵ 
  new_md5=`md5sum ${res_file} | awk '{print $1}'`
  # ����ǵ�һ��,�͸�ֵ�Ƚ��õ�md5
  [ -z ${res_md5} ] && res_md5=${new_md5}
  # ���md5�������ļ��仯
  if [[ ${new_md5} != ${res_md5} ]];then
    # ��¼md5�仯����
    res_md5=${new_md5}
    
    # ��ȡasr����
    asr_content=`cat ${asr_file}`
    # ��ȡres����
    res_content=`cat ${res_file}`

    
    miai_domain=`echo "${res_content}"|awk -F '"domain": ' '{print $2}'|awk -F '"' '{print $2}'`
    miai_errcode=`echo "${res_content}"|awk -F '\"extend\":' '{print $2}'|awk -F '\"code\": ' '{print $2}'|awk -F ',' '($1>200){print $1}'`

    echo "== �����ݸ��� | domain: ${miai_domain} errcode: ${miai_errcode}"
    
    if ([[ ! -z ${asr_keywords} ]] && [[  ! -z `echo "${asr_content}"|awk 'match($0,/'${asr_keywords}'/){print 1}'` ]]) || ([[ ! -z ${res_keywords} ]] && [[  ! -z `echo "${res_content}"|awk 'match($0,/'${res_keywords}'/){print 1}'` ]]) || [ ${miai_errcode} ];then
      echo "== ��ͼֹͣ"

      # @TODO: doamin��scenes�������,��ͣ����,��¼����״̬����ͣ�Լ���������ʱ�������
      # Ϊ�˱�֤��Ӱ����ͣЧ��,���Ե�����ͬ��ֹͣ���ŷ�ʽ
      if [ "${miai_domain}" != "scenes" ];then
        echo "== ����ģʽ | ${miai_domain}"
        # ����ѭ��,ֱ��resume�ɹ�һ��ֱ������
        seq 1 200 | while read line;do
          code=`ubus call mediaplayer player_play_operation {\"action\":\"resume\"}|awk -F 'code":' '{print $2}'`
          if [[ "${code}" -eq "0" ]];then
            echo "== ֹͣ�ɹ�"
            break
          fi
          sleep 0
        done
      else
        echo "== ����ģʽ | ${miai_domain}"
        seq 1 10 | while read line;do
          ubus call mediaplayer player_play_operation {\"action\":\"stop\"} > /dev/null 2>&1
          sleep 0
        done
      fi
 
      # ��¼����״̬����ͣ,������HA�����������߼���ʱ�򲻻�岥����,0Ϊδ����,1Ϊ������,2Ϊ��ͣ
      play_status=`ubus -t 1 call mediaplayer player_get_play_status | awk -F 'status' '{print $2}' | cut -c 5`
      if [ "${miai_domain}" != "scenes" ];then
        ubus call mediaplayer player_play_operation {\"action\":\"pause\"} > /dev/null 2>&1
      fi
 
      # @todo:
      # ת��asr��res������˽ӿ�,Զ�˿��Դ�������߼���ɺ󷵻���Ҫ������TTS�ı�
      # 2�����ӳ�ʱ,4�봫�䳬ʱ
      tts=`curl --insecure �Cconnect-timeout 2 -m 2 -s -u "${nodered_auth}" --data-urlencode "asr=${asr_content}" --data-urlencode "res=${res_content}" "${nodered_url}/miai"`
      echo "== �������"

      # ���Զ�˷������ݲ�Ϊ������TTS����֮
      if [[ -n "${tts}" ]];then
        echo "== ����TTS | TTS����: ${tts}"
        ubus call mibrain text_to_speech "{\"text\":\"${tts}\",\"save\":0}" > /dev/null 2>&1
        # �20��TTS����ʱ��,20������������������
        seq 1 20 | while read line;do
          media_type=`ubus -t 1 call mediaplayer player_get_play_status|awk -F 'media_type' '{print $2}'|cut -c 5`
          if [ "${media_type}" == "" ] || [ "${media_type}" -ne "1" ];then
            echo "== ����TTS����"
            break
          fi
          sleep 1
        done
      fi
 
      # ���֮ǰ�����ǲ��ŵ�����Ų���
      if [[ "${play_status}" -eq "1" ]];then
        echo "== ������������"
        # �����ӳ�һ������Ϊǰ�洦�����̫��,��������ָ����Ų��ɹ�
        sleep 1
        if [ "${miai_domain}" != "scenes" ];then
          ubus call mediaplayer player_play_operation {\"action\":\"play\"} > /dev/null 2>&1
        fi
      fi
    fi

    log_res=`curl --insecure �Cconnect-timeout 2 -m 2 -s -u "${nodered_auth}" --data-urlencode "asr=${asr_content}" --data-urlencode "res=${res_content}" "${nodered_url}/miai/set/log"`
    echo "== Ͷ��־ | ${log_res}"
  fi
 
  # ��ĳƵ��ȥ�������ش�
  if [[ "${keywords_update_timeout}" -gt "0" ]];then
    now=`date +%s`
    step=`expr ${now} - ${last_time}`
    # �����趨ʱ������ȡ���´�
    if [[ "$step" -gt "${keywords_update_timeout}" ]];then
        asr_keywords=`curl --insecure �Cconnect-timeout 2 -m 2 -s -u "${nodered_auth}" "${nodered_url}/miai/get/asr"`
        res_keywords=`curl --insecure �Cconnect-timeout 2 -m 2 -s -u "${nodered_auth}" "${nodered_url}/miai/get/res"`
        echo "== ���¹ؼ��� | asr�ؼ�������: ${asr_keywords} | res�ؼ�������: ${res_keywords}"
        last_time=`date +%s`
    fi
  fi
  sleep 10
done