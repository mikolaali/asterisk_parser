# asterisk_parser
Parser for full log. asterisk >= 11.0
Парсер выполнен на awk - ужасная поделка, изначально задумка была простая,
но потом услажнилась , и средств awk оказалась крайне не достаточно , чтобы код был читаемый

Пример использование скрипта.
awk -f parser.sh debug=1 \
/etc/asterisk/extensions.conf \   # read asterisk dialplan
/etc/asterisk/template/extensions.conf \  # custom dialplan
C-004d0c2d 2>/dev/null > C-004d0c2d.conf   # callid
