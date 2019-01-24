# @author FlashSoft
# root=`pwd`
root=""
# �ű���ŵ�ַ
#�ڰ� mico_path="${root}/root/mico.sh"
mico_path="${root}/data/mico.sh"
# �ű���������
#�ڰ� mico_initpath="${root}/etc/init.d/mico_enable"
mico_initpath="${root}/data/mico_enable"
mico_tmppath="/tmp"
rm $mico_initpath > /dev/null 2>&1
echo "==============================================================="
echo ""
echo "     ��ӭʹ��'С��������'��װ���� v0.9(2018.10.31)"
echo ""
echo "     ������ͨ������С����ʶ��ʺ���Ӧ��"
echo "     �����ص�����ת����NodeRed��������Զ����豸�Ĳ���"
echo "     ��̳��ַ https://bbs.hassbian.com/thread-5110-1-1.html"
echo ""
echo "==============================================================="
echo ""
 
# �������,����ΪС�������ż���
[ -z "`uname -a|grep mico`" ] && echo "��ǰ����С���豸,�뵽С����ִ�д�����" && exit


echo "[!!!ע��] ��Ҫ����NodeRed�������ṩ��/miai������get�ӿ�(������̳�ṩ�����ͺ�)"
echo "������NodeRed�����ַ,Ĭ��ֵ[http://nodered:1880]:"
read -p "" nodered_url
[ -z "${nodered_url}" ] && nodered_url="http://nodered:1880"

echo "���������NodeRed���˺ź�����,���û��������ֱ�ӻس�:"
echo "��ʽΪ �˺�:����"
read -p "" nodered_auth
[ -z "${nodered_auth}" ] && nodered_auth='root:vvpivcol' #bytt

echo "[!!!ע��] asr���ش�Ϊ���С���Լ�˵�Ļ�"
echo "������asr���ش�,������ش�ʹ��|�ָ�,Ĭ��ֵΪ[��]:"
read -p "" asr_keywords
[ -z "${asr_keywords}" ] && asr_keywords=""

echo "[!!!ע��] res���ش�ΪС���������Ӧ����"
echo "������res���ش�,������ش�ʹ��|�ָ�,Ĭ��ֵΪ[��]:"
read -p "" res_keywords
[ -z "${res_keywords}" ] && res_keywords=""

echo "��������Ӧ���شʵĸ���Ƶ��,��λ��,0Ϊ������,Ĭ��ֵ[0]:"
read -p "" keywords_update_timeout
[ -z "${keywords_update_timeout}" ] && keywords_update_timeout=0

echo "==============================================================="
echo ""
echo "      NodeRed�����ַ: ${nodered_url}"
echo "      NodeRed�˺�����: `[ "${nodered_auth}" == ":" ] && echo "������" || echo "������"`     "
echo "            asr���ش�: `[ "${asr_keywords}" == "" ] && echo "�����ش�" || echo ${asr_keywords}`    "
echo "            res���ش�: `[ "${res_keywords}" == "" ] && echo "�����ش�" || echo ${res_keywords}`    "
echo "       ���شʸ���Ƶ��: `[ "${keywords_update_timeout}" == "0" ] && echo "������" || echo ${keywords_update_timeout}`    "
echo ""
echo "==============================================================="

echo "������Ϣ�Ƿ���ȷ�������������װ,ctrl+cȡ����װ:"
read -p "" enterkey

echo "��ʼ��֤nodered�����Ƿ�ͨ��"
echo ""
header=`curl --insecure �Cconnect-timeout 2 -m 4 -sI -u "${nodered_auth}" ${nodered_url}|head -n 1`
echo "״̬��Ϣ: ${header}"
echo ""
if [ -z "`echo ${header}`" ];then
  echo "��֤��ͨ��: NodeRed��ַ��ͨ"
  exit
else
  if [[ "`echo $header|awk '{print $2}'`" -eq "401" ]];then
    echo "��֤��ͨ��: NodeRed���벻��ȷ"
    exit
  else
    echo "��֤ͨ��"
  fi
fi

if [ -d "/tmp/mibrain" ];then
  echo "С���̼��汾: �ɰ�̼�"
else
  if [ -d "/tmp/mipns/mibrain" ];then
    mico_tmppath="/tmp/mipns" 
    echo "С���̼��汾: �°�̼�"
  else
    echo "С���̼��汾: δ֪�̼��汾"
    exit
  fi
fi

# ����Զ�̽ű�������Ƿ�ɹ�
now=`date +%s`
mico=`curl --insecure -s �Cconnect-timeout 4 -m 4 "https://raw.githubusercontent.com/FlashSoft/mico/dev/mico.sh?${now}"`
# mico=`cat ./mico.sh`
if [[ -z `echo "${mico}"|awk 'match($0,/FlashSoft/){print 1}'` ]];then
  echo "�ű����ز��ɹ�,��������Ҫ��������"
  exit
fi

# �滻�������洢
echo "${mico}" |
awk '{gsub("^asr_keywords=.*", "asr_keywords=\"'${asr_keywords}'\""); print $0}' |
awk '{gsub("^res_keywords=.*", "res_keywords=\"'${res_keywords}'\""); print $0}' |
awk '{gsub("^keywords_update_timeout=.*", "keywords_update_timeout='${keywords_update_timeout}'"); print $0}' |
awk '{gsub("^nodered_url=.*", "nodered_url=\"'${nodered_url}'\""); print $0}' |
awk '{gsub("^asr_file=.*", "asr_file=\"'${mico_tmppath}'/mibrain/mibrain_asr.log\""); print $0}' |
awk '{gsub("^res_file=.*", "res_file=\"'${mico_tmppath}'/mibrain/mibrain_response.log\""); print $0}' |
awk '{gsub("^nodered_auth=.*", "nodered_auth=\"'${nodered_auth}'\""); print $0}' > $mico_path
chmod a+x $mico_path


# ����ű�
echo "���������ű�"
echo "#!/bin/sh /etc/rc.common
START=96
start() {
  sh '${mico_path}' &
}

stop() {
  kill \`ps|grep 'sh ${mico_path}'|grep -v grep|awk '{print \$1}'\`
}" > $mico_initpath
chmod a+x $mico_initpath > /dev/null 2>&1
$mico_initpath enable > /dev/null 2>&1
$mico_initpath stop > /dev/null 2>&1

echo "��װ���"
echo "����ʹ��/etc/init.d/mico_enable start ����С��������"