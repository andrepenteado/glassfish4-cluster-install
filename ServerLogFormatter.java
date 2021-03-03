//package br.unesp.util;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.logging.LogRecord;
import java.util.logging.SimpleFormatter;
import java.util.regex.Pattern;
public class ServerLogFormatter extends SimpleFormatter {
    private final String newLine = System.getProperty("line.separator");
    @Override
    public synchronized String format(LogRecord record) {
        StringBuffer sb = new StringBuffer();
        String msg = record.getMessage();
        Pattern p = Pattern.compile("\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2},\\d{3}");
        if (msg == null || msg.length() <= 23 || !p.matcher(msg.substring(0, 23)).matches()) {
            // time only
            Date dt = new Date();
            dt.setTime(record.getMillis());
            sb.append(new SimpleDateFormat("dd/MM/yyyy HH:mm:ss,SSS").format(dt));
            sb.append(" ");
            // truncar com 5, ou preencher com espaços até 5
            String sLevel = record.getLevel().getName();
            int numSpaces = 5 - sLevel.length();
            if (numSpaces > 0) {
                for (int i = 0; i < numSpaces; i++) {
                    sb.append(" ");
                }
                sb.append(sLevel);
            }
            else {
                sb.append(sLevel.substring(0, 5));
            }
            sb.append(" | ");
        }
        // message
        sb.append(record.getMessage());
        sb.append(newLine);
        return sb.toString();
    }
}
