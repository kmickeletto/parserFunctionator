#!/bin/bash
# FortiSIEM ParserFunctions
# cdurkin@fortinet.com
# Version 10.0 - Tested with FortiSIEM 5.3.1
# June 2020
# New Extract Parser feature in 7.0 based on original code by Ken Mickeletto

echo -e "\n(c) 2020 Fortinet ATP Team - Parser Functionator - 10.0 (Updated for FSM 5.3)\n"
echo "██████╗  █████╗ ██████╗ ███████╗███████╗██████╗                                                     "
echo "██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗                                                    "
echo "██████╔╝███████║██████╔╝███████╗█████╗  ██████╔╝                                                    "
echo "██╔═══╝ ██╔══██║██╔══██╗╚════██║██╔══╝  ██╔══██╗                                                    "
echo "██║     ██║  ██║██║  ██║███████║███████╗██║  ██║                                                    "
echo "╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝                                                    "
echo "███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ████████╗ ██████╗ ██████╗ "
echo "██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗"
echo "█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝"
echo "██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗"
echo "██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║"
echo "╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝"
#echo -e "\nPlease wait for menu.....\n"
RED='\033[31m'
NC='\033[0m'

version=$(cat /opt/phoenix/bin/VERSION | grep -oP -m1 '\d+\.\d+\.\d+')
currentDir=`pwd`

preprocessing(){
#Grab XMLs
mkdir -p $currentDir/XMLs
cp -n /opt/phoenix/config/xml/*.xml $currentDir/XMLs

#Remove Bad XMLs
rm -rf $currentDir/XMLs/PHRuleIncidentParser.xml

#Produce Parser List
setAttrFunctionList=`grep '<setEventAttribute attr=".*".*(.*)</.*>' $currentDir/XMLs/*.xml | grep -Po '(?<=>).*(?=<)' | grep -oP '^[^(]*'`
collectAndSetFunctionList=`grep '<collect' $currentDir/XMLs/*.xml |  grep -Po '(?<=<).*(?= )' | grep -oP '^[^ ]*(?:)'`

IFS=$'\n'
for value in $setAttrFunctionList
do
  if [[ $value != *"CDATA"* ]];then
    if [[ ! " ${setAttrFunctionArray[@]} " =~ $(echo "$value") ]]; then
      setAttrFunctionArray=( "${setAttrFunctionArray[@]}" $(echo $value) )
    fi
  fi
done
printf "%s\n" "${setAttrFunctionArray[@]}" > ${version}_SetFunctions


IFS=$'\n'
for value in $collectAndSetFunctionList
do
  if [[ $value != *"!--<"* ]] && [[ $value != *"parsingInstructions"* ]];then
    if [[ ! " ${collectAndSetFunctionArray[@]} " =~ $(echo "$value") ]]; then
      collectAndSetFunctionArray=( "${collectAndSetFunctionArray[@]}" $(echo $value) )
    fi
  fi
done
printf '%s\n' "${collectAndSetFunctionArray[@]}" > ${version}_CollectFunctions
}

preload(){
IFS=$'\n'
while read setFunction
do
  setAttrFunctionArray=( "${setAttrFunctionArray[@]}" $(echo $setFunction) )
done <${version}_SetFunctions

IFS=$'\n'
while read collectFunction
do
  collectAndSetFunctionArray=( "${collectAndSetFunctionArray[@]}" $(echo $collectFunction) )
done <${version}_CollectFunctions
}


customParser(){
customParserList=$(psql -t -A -U phoenix -d phoenixdb -c "select name from ph_event_parser where sys_defined is false")
IFS=$'\n'
for parser in $customParserList
do
if [[ ! " ${customParserArray[@]} " =~ $(echo "$parser") ]]; then
  customParserArray=( "${customParserArray[@]}" $(echo $parser) )
fi
done
}

systemParser(){
systemParserList=$(psql -t -A -U phoenix -d phoenixdb -c "select name from ph_event_parser where sys_defined is true")
letter=$1
IFS=$'\n'
for parser in $systemParserList
do
if [[ ! " ${systemParserArray[@]} " =~ $(echo "$parser" | grep -Po "^$letter.*") ]]; then
  systemParserArray=( "${systemParserArray[@]}" $(echo $parser) )
fi
done
}

allParser(){
allParserList=$(psql -t -A -U phoenix -d phoenixdb -c "select name from ph_event_parser")
letter=$1
IFS=$'\n'
for parser in $allParserList
do
if [[ ! " ${allParserArray[@]} " =~ $(echo "$parser" | grep -Po "^$letter.*") ]]; then
  allParserArray=( "${allParserArray[@]}" $(echo $parser) )
fi
done
}



mainMenu(){
PS3='Choose an option, or press enter for menu: '
options=("Display All setEventAttribute Functions" "Display All collectAndSet Functions" "Search Parsers with specific setEventAttribute Function" "Search Parsers with specific collectAndSet Function" "Display Examples of collectAndSet Function" "Search When Test Examples" "Show Switch/Case and Choose/When Formats" "List Available but Unused Functions" "Event Attribute Type (EAT) Search" "Extract A Specific SYSTEM Parser and Test Events" "Extract ALL Custom Parsers and Test Events" "Extract A Specific Custom Parser and Test Events"  "Extract A Specific Custom Parser, Test Events, and Check For Custom EATs" "View Test Events for any Parser" "View General XML Pattern Definitions" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Display All setEventAttribute Functions")
            echo -e "\n$version Inbuilt Functions for ${RED}setEventAttribute${NC}\n"
            printf '%s\n' "${setAttrFunctionArray[@]}" | sort
            echo -e "${NC}"
            ;;
        "Display All collectAndSet Functions")
            echo -e "\n$version Inbuilt Functions for ${RED}collectAndSet${NC}\n"
            printf '%s\n' "${collectAndSetFunctionArray[@]}" | sort
            echo -e "${NC}"            
            ;;
	"Search Parsers with specific setEventAttribute Function")
            echo -e "\n"	
            for index in ${!setAttrFunctionArray[*]}
            do
               printf "%4d: %s\n" $index ${setAttrFunctionArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the Function you wish to search (ie: 5):"
            read setAttrNumber
            
            echo "Displaying all Parsers and line number with ${setAttrFunctionArray[$setAttrNumber]}"
            grep -Hn --color "<setEventAttribute attr=".*">${setAttrFunctionArray[$setAttrNumber]}(" $currentDir/XMLs/*.xml
            echo -e "\n"  
            ;;
        "Search Parsers with specific collectAndSet Function")
            echo -e "\n"
            for index in ${!collectAndSetFunctionArray[*]}
            do
               printf "%4d: %s\n" $index ${collectAndSetFunctionArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the Function you wish to search (ie: 5):"
            read collectNumber

            echo "Displaying all Parsers and line number  with ${collectAndSetFunctionArray[$collectNumber]}"

            grep -Hn --color "${collectAndSetFunctionArray[$collectNumber]}" $currentDir/XMLs/*.xml
            echo -e "\n"
            ;;
        "Display Examples of collectAndSet Function")
            echo -e "\n"
            for index in ${!collectAndSetFunctionArray[*]}
            do
               printf "%4d: %s\n" $index ${collectAndSetFunctionArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the Function you wish to search (ie: 5):"
            read collectNumber

            echo "Displaying all ${collectAndSetFunctionArray[$collectNumber]} Parser samples"

            var="${collectAndSetFunctionArray[$collectNumber]}"
            variable=$(echo $var | sed 's/[ \t]*$//') 
            echo "Function is: $variable"

awk '/'$variable' /,/<\/'$variable'>/{print} /<\/'$variable'/ {print "\033[34m"FILENAME"\033[0m",$2 "\n"}' $currentDir/XMLs/*.xml | sed -e 's/^[ \t]*//' | sed '${/^$/d;}'


            echo -e "\n"
            ;;
        "Search When Test Examples")

            testMenu() {
            echo -e "\n"           
            echo -e "1) ${RED}Equals${NC} a value"
            echo -e "2) Does ${RED}NOT Equal${NC} a value"
            echo -e "3) Is ${RED}IN${NC} this list of values"
            echo -e "4) ${RED}Matches${NC} this value or Regex"
            echo -e "5) Does ${RED}NOT Match${NC} this value or Regex"
            echo -e "6) ${RED}Exists${NC} as a parsed value"
            echo -e "7) ${RED}Does NOT Exist${NC} as a parsed value"
            echo -e "8) Is ${RED}NOT a Private IP Address${NC}"
            echo -e "9) Exit When Menu"
            echo -e "\nEnter the number for the TEST, to display examples (ie: 1):"
            read testNumber

            echo -e "\n"
            if [[ $testNumber =~ "1" ]]; then
                grep -h "when test='\\$" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 10 " ="            
            elif [[ $testNumber =~ "2" ]]; then
                grep -h "when test='\\$" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 2 "!="
            elif [[ $testNumber =~ "3" ]]; then
                grep -h "when test='\\$" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 10 " IN"
            elif [[ $testNumber =~ "4" ]]; then
                grep -h "when test=\"" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 20 "matches"
            elif [[ $testNumber =~ "5" ]]; then
                grep -h "when test=\"" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 40 "not_matches"
            elif [[ $testNumber =~ "6" ]]; then
                grep -h "when test=\"" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 10 "exist"
            elif [[ $testNumber =~ "7" ]]; then
		grep -h "when test=\"" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 10 "not_exist"                
            elif [[ $testNumber =~ "8" ]]; then
                grep -h "when test=" /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | grep --color -m 10 "private"
            elif [[ $testNumber =~ "9" ]]; then
                mainMenu
            fi
            testMenu
            }
            testMenu
            ;;

        "Show Switch/Case and Choose/When Formats")
            echo -e "Choose/When Tests ........."
            echo "
            <switch>
              <case>
                ..... 
              </case>
              <case>
                .....
              </case>
              <default>
                .....
              </default>
            </switch>"

            echo -e "\nChoose/When Tests ........."
            echo "
            <choose>
              <when test= .....>
                .....
              </when>
              <when test= .....>
                .....
              </when>
              <otherwise>
                .....
              </otherwise>
            </choose>"

            echo -e "\nBoth <default> and <otherwise> components can be omitted above, if at least one case or test will always match\n"
            ;;


        "List Available but Unused Functions")
            echo -e "\nFunctions Available but not current used (as of 5.3.1) : "
            echo -e "\ntoUpper -> ${RED}<setEventAttribute attr="_final">${NC}toUpper($_sourceVar)${RED}</setEventAttribute>${NC}\nConverts all text stored in the variable _sourceVar to Upper Case and stores in the result in the variable _final\n"
            ;;


	"Event Attribute Type (EAT) Search")
            echo -e "\nWhat Event Attribute do you want to search for? : "
            read eat
            echo -e "\nList of Parsers which reference the attribute: ${BOLD}${RED}"
            grep -Hl "$eat" XMLs/*.xml | cut -d "/" -f 2
            echo -e "\n${NOBOLD}${NC}In more detail:\n"
            grep -n --color "$eat" $currentDir/XMLs/*.xml
	    ;;


        "Extract A Specific SYSTEM Parser and Test Events")
 
            echo "Enter the first Letter of the Parser of Interest (ie: A) : "
            read letter
            
            systemParser $letter

            echo -e "\n"
            for index in ${!systemParserArray[*]}
            do
               printf "%4d: %s\n" $index ${systemParserArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the System Parser you wish to Extract (ie: 2):"
            read setAttrNumber

            echo "Displaying Test Events for Parser : ${systemParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where sys_defined is true and name='${systemParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g'
            echo -e "${NC}"

            echo -e "Test Events have been saved as ${systemParserArray[$setAttrNumber]}_TestEvents.txt"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where sys_defined is true and name='${systemParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > ${systemParserArray[$setAttrNumber]}_TestEvents.txt

            echo "Displaying first 20 lines of Parser : ${systemParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,parser_xml,NULL from ph_event_parser where sys_defined is true and name='${systemParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' | head -n 20
            echo -e "${NC}"

            echo -e "Parser has been saved as ${systemParserArray[$setAttrNumber]}.xml\n"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,parser_xml,NULL from ph_event_parser where sys_defined is true and name='${systemParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > ${systemParserArray[$setAttrNumber]}.xml
            exit
            ;;


        "Extract ALL Custom Parsers and Test Events")

            echo -e "Parsers and Test Events have been saved as All_Custom_Parsers.xml\n"
            psql -A -t -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select 'Parser Name: '||a.name,'Device Type: '||b.vendor||' '||b.model,'Test Events:',a.test_event,NULL,'Parser:',a.parser_xml,NULL,NULL from ph_event_parser a left join ph_device_type b on a.device_type_id = b.id where a.sys_defined is false" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > All_Custom_Parsers.xml
            exit
            ;;


        "Extract A Specific Custom Parser and Test Events")
            customParser

            echo -e "\n"
            for index in ${!customParserArray[*]}
            do
               printf "%4d: %s\n" $index ${customParserArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the Custom Parser you wish to Extract (ie: 2):"
            read setAttrNumber

            echo "Displaying Test Events for Parser : ${customParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g'
            echo -e "${NC}"
 
            echo -e "Test Events have been saved as ${customParserArray[$setAttrNumber]}_TestEvents.txt"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > ${customParserArray[$setAttrNumber]}_TestEvents.txt

            echo "Displaying first 20 lines of Parser : ${customParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,parser_xml,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' | head -n 20
            echo -e "${NC}"

            echo -e "Parser has been saved as ${customParserArray[$setAttrNumber]}.xml\n"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,parser_xml,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > ${customParserArray[$setAttrNumber]}.xml
            exit
            ;;

        "Extract A Specific Custom Parser, Test Events, and Check For Custom EATs")
            customParser

            echo -e "\n"
            for index in ${!customParserArray[*]}
            do
               printf "%4d: %s\n" $index ${customParserArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the Custom Parser you wish to Extract (ie: 2):"
            read setAttrNumber

            echo "Displaying Test Events for Parser : ${customParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g'
            echo -e "${NC}"

            echo -e "Test Events have been saved as ${customParserArray[$setAttrNumber]}_TestEvents.txt"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > ${customParserArray[$setAttrNumber]}_TestEvents.txt

            echo "Displaying first 20 lines of Parser : ${customParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,parser_xml,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' | head -n 20
            echo -e "${NC}"

            echo -e "Parser has been saved as ${customParserArray[$setAttrNumber]}.xml\n"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,parser_xml,NULL from ph_event_parser where sys_defined is false and name='${customParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g' > ${customParserArray[$setAttrNumber]}.xml

            echo -e "Analyzing Custom Parser for Custom Event Attributes ........................"
            rm -rf ${customParserArray[$setAttrNumber]}.attributes           
 
            #Test Case 1 - setEventAttribute Functions
            grep '<setEventAttribute attr=".*".*(.*)</.*>' ${customParserArray[$setAttrNumber]}.xml | grep -Po "attr=\"\K[^\"]+" > ${customParserArray[$setAttrNumber]}.attributes

            #Test Case 2 - setEventAttributes
            grep '<setEventAttribute attr=".*".*</.*>' ${customParserArray[$setAttrNumber]}.xml | grep -Po "attr=\"\K[^\"]+" > ${customParserArray[$setAttrNumber]}.attributes 
     
            #Test Case 3 - collect Function Sources
            grep '<collect' ${customParserArray[$setAttrNumber]}.xml |  grep -Po '(?<=<).*(?=\>)' | grep -Po "src=\"\\$\K[^\"]+" >> ${customParserArray[$setAttrNumber]}.attributes

            #Test Case 4 - Extract Patterns
            grep -Po '<\K\w+:[^\>]+' ${customParserArray[$setAttrNumber]}.xml | cut -d ":" -f 1 >> ${customParserArray[$setAttrNumber]}.attributes

            #Test Case 5 - KeyMaps
            grep 'attrKey' ${customParserArray[$setAttrNumber]}.xml | grep -Po "attr=\"\K[^\"]+" >> ${customParserArray[$setAttrNumber]}.attributes

            #Test Case 6 - PosMaps
            grep 'attrPos' ${customParserArray[$setAttrNumber]}.xml | grep -Po "attr=\"\K[^\"]+" >> ${customParserArray[$setAttrNumber]}.attributes

            #Test Case 7 - Set New Attribute from Attibute
            grep -Po '<setEventAttribute attr=\"[^\"]+\">\$\K[^\<]+' ${customParserArray[$setAttrNumber]}.xml >> ${customParserArray[$setAttrNumber]}.attributes

            #Test Case 8 - Remove Collect And Set From Another Event Attrs
            sed -i '/AnotherEvent/d' ${customParserArray[$setAttrNumber]}.attributes            

            cat ${customParserArray[$setAttrNumber]}.attributes | sort -u > ${customParserArray[$setAttrNumber]}.temp
            mv ${customParserArray[$setAttrNumber]}.temp ${customParserArray[$setAttrNumber]}.attributes 

            IFS=$'\n'
            while read attribute
            do
              if ! [[ $attribute =~ ^_ ]];then
                #Check If Attr is currently present or not in local system
                initial_check=$(psql -U phoenix -d phoenixdb -c "select name, sys_defined from ph_event_attr_type where name='$attribute';" | grep -Po "\(\K[^ ]+")
                if [[ "$initial_check" -eq "1" ]]; then
                   custom_check=$(psql -U phoenix -d phoenixdb -c "select sys_defined from ph_event_attr_type where name='$attribute' and sys_defined IS NOT NULL;" | grep -Po "\(\K[^ ]+")
                   if [[ "$custom_check" -eq "1" ]]; then
                     if [[ ! " ${setOnBoxCustomAttrArray[@]} " =~ $(echo "$attribute") ]]; then
                       setOnBoxCustomAttrArray=( "${setOnBoxCustomAttrArray[@]}" $(echo $attribute) )
                     fi
                   fi
                else 
                  if [[ ! " ${setOnBoxMissingCustomAttr[@]} " =~ $(echo "$attribute") ]]; then
                    setOnBoxMissingCustomAttr=( "${setOnBoxMissingCustomAttr[@]}" $(echo $attribute) )
                  fi
                fi
              fi  
            done <${customParserArray[$setAttrNumber]}.attributes
           
            array1=$(echo "${#setOnBoxCustomAttrArray[@]}")
            array2=$(echo "${#setOnBoxMissingCustomAttr[@]}")
            arraySize=$((array1 + array2))

            if [[ "$arraySize" -ne "0" ]]; then

              echo -e "\nCustom Event Attributes used in Parser: ${customParserArray[$setAttrNumber]}"
            
              #Already present on local install	
              echo -e "\nCustom Event Attributes required, but already present on this local Install${RED}"  
              localAttrList=`printf '%s\n' "${setOnBoxCustomAttrArray[@]}" | sort | sed "s/^\|$/'/g"|paste -sd, -`
              psql -t -A -U phoenix -d phoenixdb -c "select name, display_name, value_type from ph_event_attr_type where name IN ($localAttrList) order by name;" > ${customParserArray[$setAttrNumber]}.cust_attributes

              sed -i '1i Name|Display Name|Value Type' ${customParserArray[$setAttrNumber]}.cust_attributes
              cat ${customParserArray[$setAttrNumber]}.cust_attributes | sed 's/11$/"DATE"/g' | sed 's/1$/"STRING"/g' | sed 's/3$/"UCHAR"/g' | sed 's/4$/"INT16"/g' | sed 's/5$/"UINT16"/g' | sed 's/6$/"INT32"/g' | sed 's/7$/"UINT32"/g' | sed 's/9$/"UINT64"/g' | sed 's/10$/"IP"/g' | sed 's/12$/"BINARY"/g' | sed 's/14$/"DOUBLE"/g' | sed 's/15$/"BINHEX"/g' | column -t -s '|'

              #Not Defined on this Install
              echo -e "${NC}\nCustom Event Attributes also required for this parser but not currently defined${RED}"
              printf '%s\n' "${setOnBoxMissingCustomAttr[@]}"
              printf '%s\n' "${setOnBoxMissingCustomAttr[@]}" >> ${customParserArray[$setAttrNumber]}.cust_attributes
              echo -e "${NC}"
            else
                echo -e "\nCustom Parser : ${customParserArray[$setAttrNumber]}.xml does not contain any Custom Event Attributes\n"
            fi

            exit
            ;;

        "View Test Events for any Parser")

            echo "Enter the first Letter of the Parser of Interest (ie: A) : "
            read letter

            allParser $letter

            echo -e "\n"
            for index in ${!allParserArray[*]}
            do
               printf "%4d: %s\n" $index ${allParserArray[$index]}
            done

            echo -e "\nEnter the Array Index Number for the System Parser you wish to Extract (ie: 2):"
            read setAttrNumber

            echo "Displaying Test Events for Parser : ${allParserArray[$setAttrNumber]}"
            echo -e "${RED}"
            psql -t -A -F '###LINEBREAKMARKER###' -U phoenix -d phoenixdb -c "select NULL,test_event,NULL from ph_event_parser where name='${allParserArray[$setAttrNumber]}'" | perl -pe 's/###LINEBREAKMARKER###|\r/\n/g'
            echo -e "${NC}"
            ;;

	"View General XML Pattern Definitions")
            echo ""
            cat /opt/phoenix/config/xml/GeneralPatternDefinitions.xml
            echo "" 
            ;;

        "Quit")
            exit
            ;;
        *) echo invalid option;;
    esac
done
}

#Main

FILE1="${version}_SetFunctions"
FILE2="${version}_CollectFunctions"

if [[ -f "$FILE1" ]] && [[ -f "$FILE2" ]]; then
 echo -e "\nUsing cached data.....\n"
 preload 
else
 echo -e "\nPlease wait for menu.....\n"
 preprocessing
fi

mainMenu


#awk '/collectAndSetAttrByKeyValuePair /,/<\/collectAndSetAttrByKeyValuePair>/{print} /<\/collectAndSetAttrByKeyValuePair/ {print "\033[34m"FILENAME"\033[0m",$2 "\n"}' /opt/phoenix/config/xml/*.xml | sed -e 's/^[ \t]*//' | sed '${/^$/d;}'



