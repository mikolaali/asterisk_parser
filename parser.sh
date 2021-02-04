function convert_exten(){

    if ( current_exten ~ /^_/ ) {
      awk_exten = substr(current_exten,2)
      gsub(/X/,"[0-9]",awk_exten)
      gsub(/\./,".*",awk_exten)
      if (dialplan_exten[current_context] != "" ) {
        dialplan_exten[current_context] = dialplan_exten[current_context] "&&" current_exten
      }
      else dialplan_exten[current_context] = current_exten
      awk_ext[current_exten] = awk_exten
      }
    else {
      if (dialplan_exten[current_context] != "" ) dialplan_exten[current_context] = dialplan_exten[current_context] "&&" current_exten
      else dialplan_exten[current_context] = current_exten
      }
  }

function dialplanExtensionSearch(contextSearch) {
if ( dialplan_exten[contextSearch] == 0 ) { return "failed"}
if ( match(dialplan_exten[contextSearch],exten) == 0 ) {
  split(dialplan_exten[contextSearch],extensions,"&&")
  for ( i = 1 ; i <= length(extensions); i++ ) {
    if (extensions[i] ~ /^_/ ) {
      if ( current_exten ~ awk_ext[extensions[i]] ) {
        if ( search_include_flag == 1 ) {
            dialplanExtensionMap[context,exten] = contextSearch "&&" extensions[i]
            return "found"
            }
        else { dialplanExtensionMap[context,exten] = extensions[i] }
      }
    }
    else {
      continue
    }
  }
  if ( dialplanExtensionMap[context,exten] == "" ) {  return "failed"  }
}
else {
       if ( search_include_flag == 1 ) {
            dialplanExtensionMap[context,exten] = contextSearch "&&" exten
            return "found"
            }
       else {
            dialplanExtensionMap[context,exten] = exten;
            return "found"  }
}
}

function dialplanStringCreate() {
result = dialplanExtensionSearch(context);
if (result == "failed" && length(included_context[context]) != 0 ) {
  search_include_flag = 1
  split(included_context[context],includeContext,"&&")
  for (countInclude = 1; countInclude <= length(includeContext);countInclude++) {
    result = dialplanExtensionSearch(includeContext[countInclude])
    if ( result == "failed" ) { continue }
    else if ( result == "found" ) {
    return }
    else continue
  }
}
}
###  Begin code for FILENAME = extensions.conf

{ split(FILENAME,fname,"/");file = fname[length(fname)] }

file == "extensions.conf" && $0 ~ /^[;#]|^$/ {next}

#  BLOCK FOR CONTEXT NAMES
file == "extensions.conf" && match($0,/^\[(.*)\](.*)/,a)  {
current_context=a[1];
}

#  BLOCK FOR process strings like    exten =>
file == "extensions.conf" && match($0,/exten => ([^,]*),([1n](\(.*\))?),(.*$)/,e) {
current_exten = e[1];
current_prior = e[2];
if ( length(e) == 3 ) { current_func= e[3] }
else { current_func = e[4] }
if (current_prior == 1 ) {prior = 1} else { prior += 1 }
dialplan[current_context,current_exten,prior]=current_func "@@@" current_prior
if ( current_context != priv_context && current_exten != priv_exten) { priority_hash[priv_context,priv_exten] = priv_prior; convert_exten() }
else if (current_exten != priv_exten ) { priority_hash[priv_context,priv_exten] = priv_prior; convert_exten() }
else if (current_context != priv_context ) { priority_hash[priv_context,priv_exten] = priv_prior; convert_exten() }
priv_exten = current_exten
priv_context = current_context
priv_prior = prior
}

#  BLOCK FOR process same => strings
file == "extensions.conf" && match($0,/same *=> *(n(\([^,]*\))?),(.*$)/,e) {
current_prior = e[1];
current_func = e[3]
prior += 1
dialplan[current_context,current_exten,prior]=current_func "@@@" current_prior
priv_exten = current_exten
priv_context = current_context
priv_prior = prior
}

# BLOCK TO PROCESS STRINGS like    include =>
file == "extensions.conf" && match($0,/include *=> *(.*$)/,e) {
include_context = e[1]; #print include_context;

if ( length(included_context[current_context]) != 0 ) included_context[current_context] = included_context[current_context] "&&" include_context
else included_context[current_context] = include_context
}


#===== START FUNCTION DEFENITION
function sum_spaces() { sp = fmt_out[channel,"sp"] * 3;spaces = ""; for(i=1;i<=sp;i++){spaces = spaces " "} }
function check_gs_ret() {
                          if ( $0 ~ "Gosub") { gs_flag = 1 }
                          if ( $0 ~ "Return") { ret_flag = 1 }
                          }
function check_context_switch() {
if ( priv_chan != channel ) { channel_change_flag = 1 }
if ( priv_context != context ) { context_change_flag = 1 }
if ( priv_exten != exten ) { exten_change_flag = 1 }

# context changed && context is first
if ( context_change_flag == 1 && counterChanContStack[channel] < 1 ) {
if ( context_added == 1 ) {return}
counterChanContStack[channel] += 1; counterChanContChain[channel] += 1;
channelContextChain[channel,counterChanContChain[channel]] = context;
channelContextStack[channel,counterChanContStack[channel]] = context;
context_added = 1
return
}
# context changed && goto_flag = 1
if ( context_change_flag == 1 && goto_flag == 1) {
if ( context_added == 1 ) { return }
counterChanContChain[channel] += 1; channelContextChain[channel,counterChanContChain[channel]] = context;
counterChanContStack[channel] += 1; channelContextStack[channel,counterChanContStack[channel]] = context;
context_added = 1
return
}
# context changed && gs_flag = 1
if ( context_change_flag == 1 && gs_flag == 1 ) {
if ( context_added == 1 ) {return}
counterChanContChain[channel] += 1; channelContextChain[channel,counterChanContChain[channel]] = context;
counterChanContStack[channel] += 1; channelContextStack[channel,counterChanContStack[channel]] = context;
context_added = 1
return
}
# context changed && ret_flag = 1
if ( context_change_flag == 1 && ret_flag == 1 ) {
if ( context_added == 1 ) {return}
counterChanContChain[channel] -= 1; channelContextChain[channel,counterChanContChain[channel]] = context;
counterChanContStack[channel] += 1; channelContextStack[channel,counterChanContStack[channel]] = context;
context_added = 1
return
}
}

function create_point_str(){
chain_str = channel " [ "
stack_str = channel " [ "
for (i = 1; i <= counterChanContChain[channel];i++) {chain_str = chain_str " > " channelContextChain[channel,i]}
for (i = 1; i <= counterChanContStack[channel];i++) {stack_str = stack_str " > " channelContextStack[channel,i]}
chain_str = chain_str "] "
}

function check_for_include() {
if ( match(dialplanExtensionMap[context,exten],/(.*)&&(.*)/,includeContextExten) == 0 ) {
   return context SUBSEP dialplanExtensionMap[context,exten] SUBSEP prior
}
else {
   search_include_flag = 1
   return includeContextExten[1] SUBSEP includeContextExten[2] SUBSEP prior
}
}

#====== END FUNCTION DEFENITION


#----- START 1st BLOCK  FOR LOG ANALISE
file != "extensions.conf" { gsub(/[\[\]]/,"",$0);text[NR]=$0;time[NR]=($1 " " $2); if(event_time != $2){ event_time_print=1; event_time=$2}}
#----- END 1st BLOCK

#----- START 2nd BLOCK  dialplan_point, exten,prior,context, dialplan_msg( func_name(channel, msg)
file != "extensions.conf" {if(( $6 !~ "Executing" && ( $6 ~ "Goto" || "Begin")) || $7 ~ "\/var") {print spaces "[" $2 "]",substr($0,index($0,$4));check_gs_ret(); next}   # Не разбирать строки (!Executing && $6 = Goto||Begin)||$7~"/var"

################  parse dialplan_point, exten,prior,context, dialplan_msg( func_name(channel, msg) in new stack)
dialplan_point=$7  # EXTEN@CONTEXT:PRIOR
split($7,e,"@");exten=e[1];split(e[2],c,":");context=c[1];prior=c[2]   # parse exten,prior,context
################  dialplan_func, dialplan_msg
dialplan_msg=substr($0,index($0,$8),length($0))                                          # dialplan_msg
split(dialplan_msg,f,"\(")
dialplan_func=f[1]                                                                     # dialplan_func
dialplan_msg=substr(dialplan_msg,index(dialplan_msg,f[2]))                             # without func_name AND (
################ channel separate
ch_count=split(dialplan_msg,ch,",")
channel=ch[1]           #  dialplan_msg, dialplan_func, channel
################ func_msg(fm), aster_msg
func_msg=substr(dialplan_msg,index(dialplan_msg,ch[2]))
fm_count=split(func_msg,fm,"\)")
if(fm_count == 2 ){func_msg=fm[1];aster_msg=fm[2]}
else
{for(i=1;i<fm_count;i++)
 {
  if(i == 1){func_msg=fm[i];continue}
  func_msg = func_msg ")" fm[i]
 }
 aster_msg=fm[fm_count]; delete fm[fm_count];
}
}
# Result of this block: exten,prior,context,channel, dialplan_func,func_msg,aster_msg  from full log
#----- END 2nd BLOCK

#----- START 3d BLOCK
file != "extensions.conf" {
if ( gs_flag == 1 && priv_context != context ) { fmt_out[channel,"sp"] += 1;sum_spaces() ;check_context_switch()}
if ( goto_flag == 1 && priv_context != context ) { fmt_out[channel,"sp"] += 1;sum_spaces() ;check_context_switch()}
#if ( goto_flag == 1 && priv_exten != exten ) { sum_spaces() ;check_context_switch()}
if ( ret_flag == 1 && priv_context != context && priv_chan == channel ) { fmt_out[channel,"sp"] -= 1; sum_spaces();check_context_switch() }
if ( dial_flag == 1 && priv_chan != channel ) { fmt_out[channel,"sp"] = fmt_out[priv_chan,"sp"] ;check_context_switch()}
if ( dial_flag == 1 && priv_context != context ) { fmt_out[channel,"sp"] += 1; sum_spaces() ;check_context_switch()}

# result of futher 5lines used in top part of this block for the next line
if (dialplan_func == "Gosub") { gs_flag = 1 } else { gs_flag = 0 }
if (dialplan_func == "Return") { ret_flag = 1 } else { ret_flag = 0 }
if (dialplan_func == "Dial") {dial_flag = 1 } else { dial_flag = 0 }
if (dialplan_func == "Goto") {goto_flag = 1 } else { goto_flag = 0 }

# If line has Gosub or Return in ExecIf func, we must find it in function check_gs_ret()
check_gs_ret()

# Maybe current line , have changes in channel or exten, checkit
check_context_switch()

if ( context_change_flag == 1 ) { create_point_str(); print chain_str ;counterChanContextPointer[channel] += 1;
channelContextPointer[channel,counterChanContextPointer[channel]] = chain_str;
channelContextFullHistory[channel] = stack_str}

# Find appropriate string in extensions.conf for current log line
if ( debug == 1 ) {
  if ( dialplanExtensionMap[context,exten] == "" ) { dialplanStringCreate() }
  indexDialplan = check_for_include()
  if (indexDialplan in dialplan ) {
    if ( search_include_flag == 1 ) {
      split(indexDialplan,includeContextLocal,SUBSEP)
      split(dialplan[indexDialplan],dialplanLine,"@@@")  # dialplanLine[1] - func+params; dialplanLine[2] - prior
      print spaces,"included from [" includeContextLocal[1] "]: exten => "includeContextExten[2] "," dialplanLine[2] "," dialplanLine[1]
      }
    else {
      split(dialplan[indexDialplan],dialplanLine,"@@@")  # dialplanLine[1] - func+params; dialplanLine[2] - prior
      print spaces, "ext.conf: exten => " dialplanExtensionMap[context,exten] "," dialplanLine[2] "," dialplanLine[1]
         }
  }
  else {
    print length(dialplan), "there are no index ", indexDialplan, "in dialplan"
  }
}
printf "%s%s,%s,%s,%s\n", spaces,prior,exten,dialplan_func,func_msg

priv_context = context; priv_exten = exten; priv_chan = channel
channel_change_flag = 0; context_change_flag = 0; exten_change_flag = 0; context_added = 0; search_include_flag = 0
}
#----- END 3d BLOCK
#----- START END BLOCK
END {
for (channel in counterChanContextPointer) {
for (i=1; i <= counterChanContextPointer[channel]; i++) {
print channelContextPointer[channel,i]
}
}
for (channel in channelContextFullHistory) {
print "all context for channel " channel " : " channelContextFullHistory[channel]
}
}