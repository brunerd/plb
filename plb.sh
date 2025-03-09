#!/bin/zsh
#!/bin/bash
#!/bin/sh
#if you embed plb in your own script it works in these shells
#plb.min.sh a minified version for embedding in your script is also available
#plx is an even smaller variant for extraction only (no crawling output)

# Usage: plb [options] [file] [query]
function plb()(
: <<-LICENSE_BLOCK
plb - "plist broker" (https://github.com/brunerd/plb) - Copyright (c) 2024 Joel Bruner
Licensed under the MIT License: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
LICENSE_BLOCK

	#quiets xtrace within plb if embedding in your own script
	{ set +x; } &> /dev/null
	#if zsh, word split on IFS
	[ -n "${ZSH_NAME}" ] && set -y

	helpText=$'plb 1.0 - plist broker (https://github.com/brunerd/plb)\nA tool for exploring and extracting data within plists\n\nUsage:\n plb [option] [file/domain] [query]\n\nArguments:\n [file/domain] - Optional (if piped/redirected input), filepath or preference domain name\n [query] - Optional, key name or colon-delimited key path, pipe delimit paths in data encoded plists\n\nDescription:\n \xE2\x80\xA2 plb takes a binary or ascii property list and renders it as either plaintext, XML, or JSON\n \xE2\x80\xA2 Input can come from file redirection, piped input, filepath or domain name argument\n \xE2\x80\xA2 Individual values can be extracted using a colon delimited key path (PlistBuddy-style)\n   \xC2\xB0 Use a pipe character (quoted or escaped) to specify paths within plists encoded as data\n \xE2\x80\xA2 Data types are decoded and output raw or if plist or JSON data, processed further\n \xE2\x80\xA2 By default simple types (except data) are output as plaintext\n \xE2\x80\xA2 Dicts are always output as an XML property list (and not plaintext, unless empty)\n \xE2\x80\xA2 Arrays are rendered as plaintext only if they do not contain dict or data types\n \xE2\x80\xA2 Date types remain in native ISO 8601 format, use -e to convert to epoch\n\nOptions (pick one):\n\n Help/Informational:\n  -d get user domains, newline delimited from `defaults domains`\n  -D get ByHost user domains that match host UUID\n  -h this help text\n  -f file path of given domain name\n\n All plist abstract types:\n  -b output plist or query results in binary property list format\n  -c[cc] Crawl plist or query results with increasing levels of detail (path -> type -> value)\n     -c Colon delimited key paths\n    -cc Add abscract type of the node delimited with ` >>> `\n   -ccc (or -v) Print value of simple types; data types output as plaintext, formatted XML/JSON, or xxd dump\n  -C[CC] Crawl plist and also traverse the plists within data keys in increasing detail (path -> type -> value)\n     -C Colon delimited key paths; plists in data keys are indentated with pipe (|) delimitation in key paths\n    -CC Add abscract type of the node delimited with ` >>> `\n   -CCC (or -V) Print value of simple types; data types output as plaintext, formatted XML/JSON, or xxd dump\n  -j convert plist or query results to JSON (all types coerced to strings)\n  -p print plist or query results using PlistBuddy\n  -r raw output; inhibits further processing of XML, plist, or JSON data within string or data types\n  -t print abstract type of plist or query results\n  -x ensure XML output; inhibits both data type decoding and plaintext output\n\n Array and Dictionary types (only):\n  -l list all keys within a dictionary or print length of an array\n\n Data types (only):\n  -F `file` type of decoded base64 data\n  -s plaintext string of base64 encoded data (whitespace removed)\n\n Date types (only):\n  -e output ISO 8601 date in epoch time instead\n  \nXML property list abstract types:\n Simple/primitive types: string, integer, date, data, real, bool\n Complex/container types: dict, array\n\nReferences:\n  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/AboutPropertyLists/AboutPropertyLists.html\n  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/UnderstandXMLPlist/UnderstandXMLPlist.html\n  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/Introduction/Introduction.html\n  man pages: plist(5), plutil(1), PlistBuddy(8), defaults(1)\n  \nExamples:\n\n#zsh only, this ignores comment lines if you copy/paste the examples\n set -k\n\n#list all the key names in a pref domain (or specified path)\n plb -l .GlobalPreferences\n\n# plb will decode binary plist data and display as plaintext if possible or XML if not\n plb com.apple.CloudSubscriptionFeatures.cache :ai.apps.image-playground\n\n# You can inhibit decoding of a plists in data types with -x (not so useful)\n plb -x com.apple.CloudSubscriptionFeatures.cache :ai.apps.image-playground\n\n# Add the pipe character and it traverses into the data even with -x or -j for JSON\n plb -x com.apple.CloudSubscriptionFeatures.cache \':ai.apps.image-playground|\'\n plb -j com.apple.CloudSubscriptionFeatures.cache \':ai.apps.image-playground|\'\n\n# List all key names within plist data\n plb -l com.apple.CloudSubscriptionFeatures.cache \':ai.apps.image-playground|\'\n\n# Specify a path within a data plist after a pipe character (quoted or escaped)\n plb com.apple.CloudSubscriptionFeatures.cache \':ai.apps.image-playground|:value:canUse\'\n\n# Dates can be output in epoch with -e, otherwise they are ISO 8601\n plb -e com.apple.CloudSubscriptionFeatures.cache \':ai.apps.image-playground|:fetched\'\n\nAdvanced Examples:\n\n#comma separated list of large preference domains to skip\nskipDomains="com.apple.audio.AudioComponentCache,com.apple.SpeakSelection,com.apple.garageband10,com.apple.EmojiCache,com.apple.audio.InfoHelper"\n\n#1 Get key paths and values for all user preferences \n# substitute `plb -D` for ByHost user prefs\nIFS=$\'\\\\n\'; for domain in $(plb -d); do\n #skip large domains\n grep -qE \'(^|,)\'"${domain}"\'(,|$)\' <<< "${skipDomains}" && continue\n echo "## Domain: $domain"; echo "## File Path: $(plb -f "${domain}")"; plb -V "${domain}"; echo\ndone\n\n#2 Get key paths and values for all .plist files in /Library/Preferences\nIFS=$\'\\\\n\'; for domain in $(find /Library/Preferences -type f -name \'*plist\'); do\n grep -qE "(^|,)${domain}(,|$)" <<< "${skipDomains}" && continue\n echo "## Domain: $domain"; echo "## File Path: $(plb -f "${domain}")"\n # Adjust the info level/output below\n plb -V "${domain}"; echo\ndone\n\n# Examples 1 & 2 exercises\n # Adjust the info level/output from -V to -CC or -C then try shallower crawls with -cc and -c\n # Output XML with `plb -x`, JSON with `plb -j`; both are speedier than crawling but with tradeoffs\n # `plb -p` prints quickly with PlistBuddy, while key/value pairs are easily spotted, paths are not\n\n#3 Get the `file` type of all data nodes in your user prefs, you might find something interesting\nIFS=$\'\\\\n\'; for domain in $(plb -d); do\n grep -qE "(^|,)${domain}(,|$)" <<< "${skipDomains}" && continue\n echo "## Domain: $domain"\n echo "## Path: $(plb -f "${domain}")"\n #the sed at the end is if you use -CC, its removes the indents from the paths of data embedded plist\n for datapath in $(plb -cc "${domain}" | awk -F \' >>> \' \'/data$/ {print $1}\' | sed \'s/^ *//\'); do \n  #get file type of data and key path\n  echo "$(plb -F "$domain" "$datapath") <<< ${datapath}"\n done\n echo\ndone\n\n# Example 3 notes: \n # `plb -cc` does not go into data plists, use `plb -CC` to search within data plists\n # Use the awk field separator `-F \' >>> \'` to easily parse -cc/-CC output ($1 paths, $2 type)\n\nRelated blog articles at: https://www.brunerd.com/blog/tag/plb\nSource and updates at: https://github.com/brunerd/plb\nplx is a smaller more spare version of plb for embedding: https://github.com/brunerd/plx'

	#############
	# FUNCTIONS #
	#############

	#possible values: dict, array, date, data, string, integer, real, true or false
	function getPlistPropertyType(){
		#if not piped in or redirected input, return 1
		[ -t '0' ] && return 1
		cat | /usr/bin/xmllint --xpath "local-name(/plist/*)" 2>/dev/null -
	}

	#plistQuery [query] <<< "${data}"
	function plistQuery(){
		#if not piped in or redirected input, return 1
		[ -t '0' ] && return 1

		#expects colon delimited path, escape single quotes \' for use in PlistBuddy
		local queryArg=$(sed $'s/\'/\\\\\'/g' <<< "${1}")

		#this method is quieter when running in xtrace mode
		local plistData; read -r -d '' plistData <<< "$(cat)"

		if ! xmllint - 2>/dev/null 1>&2 <<< "${plistData}"; then 
			#echo "error: invalid property list data." >&2
			return 1
		fi

		#if no query return same data quickly
		if [ -z "${queryArg}" ] || [ "${queryArg}" = ':' ]; then 
			/usr/bin/xmllint --format - 2>/dev/null <<< "${plistData}"
			return 0
		fi

	 	#if query specified, get final element to determine if workarounds required
		#replace escaped colons with Record Separators
		local queryArgRS=$(sed $'s/\\\\:/\x1e/g' <<< "${queryArg}")
		#take off last key name for parent path, or unset if singlular entry
		local parentPath=$(sed $'s/\x1e/\\\\:/g' <<< "${queryArgRS%:*}"); [ "${queryArg}" = "${parentPath}" ] && unset parentPath
		#get the last key in path or one and only, tests later don't need RS character replaced
		local finalElement="${queryArgRS##*:}"

		#if a key or path specified and it's not purely numbers
		if [ -n "${finalElement}" ] && ! grep -q -E '^\d+$' <<< "${finalElement}"; then 
			#get parent xml (or whole doc)
			local parentXMLData; read -r -d '' parentXMLData <<< "$(/usr/libexec/PlistBuddy -x -c "print '${parentPath}'" /dev/stdin 2>/dev/null <<< "${plistData}")"
			#get type of the xml data
			local parentPathDataType=$(getPlistPropertyType <<< "${parentXMLData}")
			#workaround: PlistBuddy prints element 0 of array if a non-numeric reference is given (instead of failing)
			if [ "${parentPathDataType}" = "array" ]; then 
				 echo "error: cannot resolve non-numeric key name for array: ${parentPath}" >&2
				 return 1
			fi
			#workaround:PlistBuddy fails to resolve keys named "CF$UID" if it is the only entry in a dictionary
			if [ "${finalElement}" = 'CF$UID' ] && [ "$(grep -c '<key>' <<< "${parentXMLData}")" = "1" ]; then 
				#only needed if type is integer (it always is really)
				grep -q '<integer>' 2>/dev/null <<< "${parentXMLData}" && local CFUIDFIX=1
			fi
		fi

		if ((CFUIDFIX)); then 
			#workaround: change integer to string to query, then change back again)
			/usr/libexec/PlistBuddy -x -c "print '${queryArg}'" /dev/stdin 2>/dev/null <<< "$(sed 's/integer>/string>/g' <<< "${plistData}")" | sed 's/string>/integer>/g' | /usr/bin/xmllint --format - 2>/dev/null
		else 
			/usr/libexec/PlistBuddy -x -c "print '${queryArg}'" /dev/stdin 2>/dev/null <<< "${plistData}" | /usr/bin/xmllint --format - 2>/dev/null
		fi
	}

	#arrays and dicts only
	function listKeysOrLength(){
		#if not piped in or redirected input, return 1
		[ -t '0' ] && return 1
		local plistData; read -r -d '' plistData <<< "$(cat)"
		local dataType=$(/usr/bin/xmllint --xpath "local-name(/plist/*)" 2>/dev/null - <<< "${plistData}")
		case "${dataType}" in
			#list names of keys, escape colons
			"dict")
				/usr/bin/xmllint --xpath "/plist/dict/key/text()" - 2>/dev/null <<< "${plistData}" | /usr/bin/perl -MHTML::Entities -pe 'decode_entities($_)' | sed 's/:/\\:/g'
			;;
			#length of the array
			"array")
				/usr/bin/xmllint --xpath "count(/plist/array/*)" - 2>/dev/null <<< "${plistData}"
			;;
			*)
				echo "error: list/length requires dict or array" >&2
				return 1
			;;
		esac
		return 0
	}

	#converts plist data to json, can handle arrays and dicts with plutil and single values with xpath and jse
	function plist2json(){
		#pipe in or redirect input, otherwise return 1
		[ -t '0' ] && return 1
		function jse()({ set +x; } &> /dev/null;JSCode=$'var argument=decodeURIComponent(escape(arguments[0]));var optionsArg = arguments[1] || \'{}\';var option = {};for (var i=0; i < optionsArg.length; i++) {switch (optionsArg.charAt(i)) { default: option[optionsArg.charAt(i)]=true; break; }};if (option.f) {try { var text = readFile(argument) } catch(error) { throw new Error(error); quit();};if (argument === "/dev/stdin") { text = text.slice(0,-1) }}else {var text=argument};print(JSON.stringify(text,null,0).replace((option.u ? /[\\u0000-\\u001f\\u007f-\\uffff]/g : /\\u007f/g), function(chr) { return "\\\\u" + ("0000" + chr.charCodeAt(0).toString(16)).slice(-4)}))';jsc=$(find "/System/Library/Frameworks/JavaScriptCore.framework/Versions/Current/" -name 'jsc');[ -z "${jsc}" ] && jsc=$(which jsc);[ -n "$BASH_VERSION" ] && unset OPTIND OPTARG;while getopts ":fhu" optionArg; do case "${optionArg}" in 'h')echo -e "${helpText}" >&2;return 0;;*)optionArgs+="${optionArg}";;esac;done;[ $OPTIND -ge 2 ] && shift $((OPTIND-1));if ! [ -t '0' ]; then optionArgs+="f";"${jsc}" -e "${JSCode}" -- "/dev/stdin" "${optionArgs}" <<< "$(cat)";else argument="${1}";if [ -z "${argument}" ]; then echo -e "${helpText}">&2;exit 0;elif grep -q "f" <<< "${optionArgs}" && ! [ -f "${argument}" ]; then echo "File not found: \"${argument}\"" >&2;exit 1;fi;"${jsc}" -e "${JSCode}" -- "${argument}" "${optionArgs}";fi)
		local plistData; read -r -d '' plistData <<< "$(cat)"
		local dataType=$(/usr/bin/xmllint --xpath "local-name(/plist/*)" 2>/dev/null - <<< "${plistData}")
		case "${dataType}" in
			#if either, change everything within to a string, plutil won't convert anything else
			"array"|"dict")
				sed -e 's/date>/string>/g; s/data>/string>/g; s/real>/string>/g; s/integer>/string>/g;' -e "s,<true/>,<string>true</string>,g; s,<false/>,<string>false</string>,g" -e 's/^[[:space:]]*//g; s/[[:space:]]*$//g' /dev/stdin 2>/dev/null <<< "${plistData}" | tr -d $'\n' | plutil -convert json -r - -o - 2>/dev/null; echo;
			;;
			#simply get the text of the single key and encode as a string
			*)
				sed -e "s,<true/>,<string>true</string>,g; s,<false/>,<string>false</string>,g" <<< "${plistData}" | xmllint --xpath '/plist/*/text()' - 2>/dev/null | /usr/bin/perl -MHTML::Entities -pe 'decode_entities($_)' | jse
			;;
		esac
	}

	#crawls a plist recursively printing out path and additional info: crawlPlist [-t] [infoLevel 1-3]
	function crawlPlist(){
		#pipe in or redirect input, otherwise return 1
		[ -t '0' ] && return 1
		local plistData; read -r -d '' plistData <<< "$(cat)"

		#options processing
		[ -n "${BASH_VERSION}" ] && local OPTIND OPTARG
		while getopts ":t" option; do
			#will descend into plist data in data type keys
			case "${option}" in	't')traverseDataPlist="1";;esac
		done
		[ $OPTIND -ge 2 ] && shift $((OPTIND-1))

		#set this if not specified
		local infoLevel="${1:-1}"
		#pass current path to recursive calls
		local myPath="${2}"
		#fix up path: add colon if path is empty or ends in | (but not not if escaped or already ends with :)
		(awk '/^$/ {exit 0} /:$/ {exit 1} /\\\|$/ {exit 1} /\|$/ {exit 0} {exit 1}' &>/dev/null <<< "${myPath}") && myPath="${myPath}:"
		#passed value if we are in an encoded plist to set indent
		local plistLevel="${3:-0}"
		local indentOffset="$((4 * plistLevel))"
		#get type of plist
		local myType=$(getPlistPropertyType <<< "${plistData}")

		#if data type either of these cases require a closer looks at data within
		if [ "${myType}" = "data" ]  && (((infoLevel == 3)) || ((traverseDataPlist))); then 
			#decode data , get file type
			read -r -d '' data_b64 <<< "$(/usr/bin/xmllint --xpath "/plist/data/text()" - 2>/dev/null <<< "${plistData}")"
			local dataFileType=$(base64 -D <<< "${data_b64}" | file -b -)

			case "${dataFileType}" in
				#xml may or may not be a plist
				"XML 1.0 document text"*)
					#decode data, we don't know yet if it is truly a plist
					read -r -d '' data <<< "$(base64 -D <<< "${data_b64}")"

					#if it lints as a plist, it is one, otherwise it is not
					if plutil -lint - 2>/dev/null 1>&2 <<< "${data}"; then 
						dataIsPlist=1
					else 
						read -r -d '' data <<< $(/usr/bin/xmllint --format - 2>/dev/null <<< "${data}")
						dataIsPlist=0
					fi
				;;
				"Apple binary property list")
					#convert to ascii xml plist
					read -r -d '' data <<< "$(base64 -D <<< "${data_b64}" | /usr/bin/plutil -convert xml1 - -o -)"
					dataIsPlist=1
				;;
				"ASCII text"*|"Unicode text"*)
					data=$(base64 -D <<< "${data_b64}")
					dataIsPlist=0
				;;
				*)
					dataIsPlist=0
				;;
			esac
		fi

		#print where we are now - levels 1 & 2 are the same for all types
		case "${infoLevel}" in
			#level 1 just our path
			1)
				cat <<< "${myPath}" | indent "${indentOffset}"
			;;
			#level 2 path and plist data type
			2)
				case "${myType}" in true|false)myType="bool";;esac
				cat <<< "${myPath} >>> ${myType}" | indent "${indentOffset}"
			;;
			3)
				#array and dict can't offer more detail than level 2
				case "${myType}" in
					"array"|"dict")
						cat <<< "${myPath} >>> ${myType}" | indent "${indentOffset}"
					;;
					#these can be output as they can't/won't be multiline
					"integer"|"date"|"real"|"true"|"false")
						#fix up true/false to bool
						case "${myType}" in true|false)myType="bool";;esac
						cat <<< "${myPath} >>> ${myType} >>> $(outputPlistAsText <<< "${plistData}")" | indent "${indentOffset}"
					;;
					#string needs some consideration if it is multiline
					"string")
						local data=$(outputPlistAsText <<< "${plistData}")
						#print multiline data indented after path
						if (($(wc -l <<< "${data}") > 1)); then 
							cat <<< "${myPath} >>> ${myType} >>>" | indent "${indentOffset}"
							indent "$((4+indentOffset))" <<< "${data}"
						#print single line data after path on same line
						else 
							cat <<< "${myPath} >>> ${myType} >>> ${data}" | indent "${indentOffset}"
						fi
					;;
					"data")
						if ((dataIsPlist)); then 
							#print our path
							cat <<< "${myPath} >>> ${myType} (${dataFileType}) >>> " | indent "${indentOffset}"
							#only print data (plist xml) if we are not traversing into it
							! ((traverseDataPlist)) && indent "$((indentOffset+4))" <<< "${data}"
						else 
							case "${dataFileType}" in
								"ASCII text"*|"Unicode text"*|"XML 1.0 document text"*)
									#more than one line indent on own lines
									if (($(($(wc -l <<< "${data}"))) <= 1)); then 
										#all on the same line
										cat <<< "${myPath} >>> ${myType} (${dataFileType}) >>> ${data}" | indent "${indentOffset}"
									else 
										cat <<< "${myPath} >>> ${myType} (${dataFileType}) >>> " | indent "${indentOffset}"
										indent "$((indentOffset+4))" <<< "${data}"
									fi
								;;
								"JSON data")
									cat <<< "${myPath} >>> ${myType} (${dataFileType}) >>>" | indent "${indentOffset}"
									base64 -D <<< "${data_b64}" | /usr/bin/plutil -convert json -r - -o - | indent "$((indentOffset+4))"; echo;
								;;
								#default is xxd hex output if file type not matched above
								*)
									cat <<< "${myPath} >>> ${myType} (${dataFileType}) >>> " | indent "${indentOffset}"
									base64 -D <<< "${data_b64}" | xxd -c 32 | indent $((4+indentOffset))
								;;
							esac
						fi
					;;
				esac
			;;
		esac

		#see if we need to go deeper into dict,array or embedded plist data
		case "${myType}" in
			"dict"|"array")
				list=$(listKeysOrLength <<< "${plistData}")
				#make list of numbers for array (except the last one like, ersatz less than for lists)
				[ "${myType}" = "array" ] && list=$(seq 0 ${list} | sed '$d')
				IFS=$'\n'
				#avoid duplicated :: if we are in root : (even though PlistBuddy ignores them)
				! (grep -q ":"$ <<< "${myPath}") && local colon=":" || local colon=""
				for item in ${list}; do
					read -r -d '' itemData <<< "$(plistQuery "${item}" <<< "${plistData}")"
					if ((traverseDataPlist)); then 
						#when passing path, escape pipe char in the item name
						crawlPlist -t "${infoLevel}" "${myPath}${colon}${item//|/\\|}" "${plistLevel}" <<< "${itemData}"
					else 
						crawlPlist "${infoLevel}" "${myPath}${colon}${item/|/\\|}" "${plistLevel}" <<< "${itemData}"
					fi
				done
			;;
			"data")
				if ((dataIsPlist)) && ((traverseDataPlist)); then 
					#pass pipe delimited parent plist path
					crawlPlist -t "${infoLevel}" "${myPath}|" "$((plistLevel+1))" <<< "${data}"
				fi
			;;
		esac
	}

	#indent text: indent [number of spaces] [characters after spaces]
	function indent(){
		[ -t 0 ] && return
		cat | sed "s/^/$(printf "%*s" ${1:-0})${2}/"
	}

	#"stringify" plist if possible
	function outputPlistAsText(){
		#pipe in or redirect input, otherwise return 1
		[ -t '0' ] && return 1
		local plistData; read -r -d '' plistData <<< "$(cat)"
		local plistDataType=$(getPlistPropertyType <<< "${plistData}")
		case "${plistDataType}" in
			#these are easily output as text, date is not reformatted like PlistBuddy
			"date"|"integer"|"real")
				/usr/bin/xmllint --xpath "/plist/${plistDataType}/text()" - 2>/dev/null <<< "${plistData}"
			;;
			#"self-closing" boolean tags don't have text(), fix up
			true) echo "true";;
			false) echo "false";;
			#use PlistBuddy to restore any and all encoded entities in string
			"string")
				local printData=$(/usr/libexec/PlistBuddy -c "print" /dev/stdin 2>/dev/null <<< "${plistData}")
				#raw output, no pretty print attempt
				if [ "${1}" = "r" ]; then 
					cat <<< "${printData}"
				else 
					local printDataType=$(file -b - <<< "${printData}")
					#some vendors encode JSON and XML as string vs. data, pretty those up too (or -r for raw)
					case "${printDataType}" in
					"XML 1.0 document text"*)
						#some vendors encode XML labeled "UTF-16" that is really not and it will fail
						if ! /usr/bin/xmllint --format - 2>/dev/null <<< "${printData}"; then 
							#if so output "raw"
							cat <<< "${printData}"
						fi
					;;
					"JSON data")
						/usr/bin/plutil -convert json -r - -o - <<< "${printData}"; echo;
					;;
					*)
						cat <<< "${printData}"
					esac
				fi
			;;
			"array")
				#only stringify if no <dict> or <data> tags exist anywhere within
				if ! grep -q -E "<dict>|<data>" <<< "${plistData}"; then 
					#convert any true/false tags into string types, output the array as text, restoring any encoded entities
					sed 's|<true/>|<string>true</string>|g; s|<false/>|<string>false</string>|g' <<< "${plistData}" | /usr/bin/xmllint --xpath '/plist/array//*[self::string or self::integer or self::real or self::date]/text()' - 2>/dev/null | /usr/bin/perl -MHTML::Entities -pe 'decode_entities($_)' 2>/dev/null
				else 
					/usr/bin/xmllint --format - 2>/dev/null <<< "${plistData}"
				fi
			;;
			"dict")
				#formatted XML output only for non-empty dicts (empty dict outputs nothing)
				if (($(listKeysOrLength <<< "${plistData}" | wc -l))); then 
					/usr/bin/xmllint --format - 2>/dev/null <<< "${plistData}"
				fi
			;;
		esac
		return 0
	}

	#find the file path of a given pref domain name, helpful when seen in `defaults domains` but not resolved (Bundle name mismatch with parent folder)
	function findDomainFilePath(){
		local domainArg="${1}"
		#normalize name, remove .plist
		local domainNameOnly="$(basename "${domainArg%.plist}")"
		#account for these other names
		case "${domainArg}" in "Apple Global Domain"|"NSGlobalDomain") domainNameOnly=".GlobalPreferences";;esac
		local homeFolder=$(/usr/libexec/PlistBuddy -c "print dsAttrTypeStandard\:NFSHomeDirectory:0" /dev/stdin 2>/dev/null <<< "$(dscl -plist . -read "/Users/$(whoami)" NFSHomeDirectory)")
		#find quickly in user prefs, then in same named Container, then deeper if needed, stops after first match
		find  "${homeFolder}/Library/Preferences" "${homeFolder}/Library/Containers/${domainNameOnly}" "${homeFolder}/Library/Containers" -type f -path '*/Library/Preferences/*' -name "${domainNameOnly}.plist" -print -quit 2>/dev/null
	}

	function getUserDomains(){
		#most reliable way to get home folder of current user
		local homeFolder=$(/usr/libexec/PlistBuddy -c "print dsAttrTypeStandard\:NFSHomeDirectory:0" /dev/stdin 2>/dev/null <<< "$(dscl -plist . -read "/Users/$(whoami)" NFSHomeDirectory)")
		#-H print user ByHost files
		if [ "${1}" = "-H" ]; then 
			local myUUID=$(/usr/libexec/PlistBuddy -c "print :0:IOPlatformUUID" /dev/stdin <<< "$(ioreg -ard1 -c IOPlatformExpertDevice)")
			defaultsDomains=$(find "${homeFolder}/Library/Preferences/ByHost" -name '*plist' 2>/dev/null | grep "${myUUID}" | sed -e "s:${homeFolder}/Library/Preferences/ByHost/::g" -e 's/\.plist$//g' | sort -d)
		else 
			#`defaults domains` leaves this one out (?!)
			[ -f "${homeFolder}/Library/Preferences/.GlobalPreferences.plist" ] && defaultsDomains=".GlobalPreferences"$'\n'
			#get what defaults knows about, newline delimited
			defaultsDomains+=$(defaults domains | sed $'s/, /\\n/g')
		fi
		[ -n "${defaultsDomains}" ] && echo "${defaultsDomains}"
	}

	#takes redirected input, quickly exits if not, no cat hang, converts ISO 8601 date to epoch
	function ISO2EPOCH(){ [ -t 0 ] && return 1; date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$(cat)" +%s; }

	########
	# MAIN #
	########

	#xmllint output lacked newlines in macOS 12 and xpath was horribly slow
	[ "$(sw_vers -productVersion | cut -d. -f1)" -lt 13 ] && { echo "error: macOS 13 or higher required" >&2; return 1; }

	#options processing
	[ -n "${BASH_VERSION}" ] && local OPTIND OPTARG
	while getopts ":bcCdDeFhjlfprstvxVz" option; do
		case "${option}" in
			'b'|'d'|'D'|'e'|'F'|'j'|'l'|'f'|'p'|'r'|'s'|'t'|'x')
				#only set option if not already set, first wins
				[ -z "${myOp}" ] && myOp="${option}"
			;;
			#-c crawl key paths, -cc add node types, -ccc add values of the node
			'c')
				[ -z "${myOp}" ] && myOp="${option}"
				[ "${myOp}" = "c" ] && let infoLevel++
			;;
			#-v (with values) same as -ccc
			'v')
				[ -z "${myOp}" ] && { myOp="c"; infoLevel="3"; }
			;;
			#-C crawl key paths PLUS recursed into data plists, -CC add node types, -CCC add values of the node
			'C')
				[ -z "${myOp}" ] && { myOp="${option}"; traverseDataPlist="1"; }
				[ "${myOp}" = "C" ] && let infoLevel++
			;;
			#-V (with values) same as -CCC which recurses into data plists
			'V')
				[ -z "${myOp}" ] && { myOp="C"; infoLevel=3; traverseDataPlist="1"; }
			;;
			#only show help if an interactive Terminal
			'h')[ -t '0' ] && echo "${helpText}" | less; exit;;
			'z')set -x;;
		esac
	done

	#list domains and quit
	case "${myOp}" in
		'd')
			getUserDomains
			return 0
		;;
		'D')
			#include ByHost domains
			getUserDomains -H
			return 0
		;;
	esac

	#shift if we have args after the options
	[ $OPTIND -ge 2 ] && shift $((OPTIND-1))

	#if piped in or redirected input
	if ! [ -t '0' ]; then 
		#since variables aren't ideal for possibly binary data, get redirected input as base64
		input_b64=$(cat|base64)
		#get file type
		input_filetype=$(base64 -D <<< "${input_b64}" | file -b -)
		case "${input_filetype}" in
			"Apple binary property list"|"XML 1.0 document text"*)
				#-p is kinda silly when piped in but let's be consistent and return a filepath and return
				[ "${myOp}" = "p" ] && { echo "/dev/stdin"; return 0; }
				#decode base64 and convert to xml1
				read -r -d '' plistData <<< "$(base64 -D <<< "${input_b64}" | plutil -convert xml1 -o - - 2>/dev/null)"
			;;
			*)
				echo "error: input is not property list data." >&2
				return 1
			;;
		esac
	else 
		fileArg="${1}"
		#get validated XML from a file
		if [ -z "${fileArg}" ]; then 
			echo "error: specify domain name or provide plist data via file argument, redirection or pipe; -h for help." >&2
			return 1
		elif [ -f "${fileArg}" ]; then 
			if ! [ -r "${fileArg}" ]; then 
				echo "error: file cannot be read, check permissions." >&2
				return 1
			fi

			input_filetype=$(file -b "${fileArg}" 2>/dev/null)
			case "${input_filetype}" in
				"Apple binary property list"|"XML 1.0 document text"*)
					#-f print file path and exit
					[ "${myOp}" = "f" ] && { echo "${fileArg}"; return 0; }
					#base64 decode and convert to xml1
					read -r -d '' plistData <<< "$(plutil -convert xml1 "${fileArg}" -o - 2>/dev/null)"
				;;
				*)
					echo "error: file is not a valid property list." >&2
					return 1
				;;
			esac
		#could be a domain
		else 
			#`defaults read` will error for non-existant domain, export does not error
			#read will fail on empty plists and domains listed in `defaults domains` whose parent folder in Containers does not match bundle id
			if defaults read "${fileArg}" 2>/dev/null 1>&2; then 
				#if -f find the file path
				[ "${myOp}" = "f" ] && { findDomainFilePath "${fileArg}"; return 0; }
				read -r -d '' plistData <<< "$(defaults export "${fileArg}" -)"
			#dig deeper for explicit path
			else 
				#look in a few places
				domainPath=$(findDomainFilePath "${fileArg}")
				#if file can't be found/read or plutil balks, error
				if ! [ -f "${domainPath}" ] || ! plistData=$(plutil -convert xml1 "${domainPath}" -o - 2>/dev/null); then 
					echo "error: file/domain \"${fileArg}\" not found/valid" >&2
					return 1
				else 
					#-p print file path and exit
					[ "${myOp}" = "f" ] && { echo "${domainPath}"; return 0; }
				fi
			fi
		fi
		#shift forward in case of query
		shift 1
	fi

	#use plutil to verify whatever we got is plist data
	if ! plutil -lint - 2>/dev/null 1>&2 <<< "${plistData}"; then 
		echo "error: invalid property list data." >&2
		return 1
 	fi

	#give it the root : if empty, if a key name contains : the user must escape like \:
 	queryArg="${1:-:}"
 	#if it ends in | add : for root (bash needs something after an IFS for loop to work, unlike zsh)
 	grep -q '|$' <<< "${queryArg}" && queryArg="${queryArg}:"

 	#replace escaped pipes with RS 0x1e
	queryArgEscaped=$(sed $'s/\\\\|/\x1e/g' <<< "${queryArg}")
	#split query on pipes for loop
	IFS=$'|'
	for queryArgElement in ${queryArgEscaped}; do
		#restore substituted pipes without escape char
		queryArgElement=$(sed $'s/\x1e/|/g' <<< "${queryArgElement}")
		#if we have looped after initial query, decode the data for next path
		if ((queryLooped)); then 
			#get base64 ascii text from data tag, remove empty lines
			read -r -d '' data_b64 <<< "$(/usr/bin/xmllint --xpath "/plist/data/text()" - 2>/dev/null <<< "${queryData}")"
			#get file type of data, this may not be a plist
			dataFileType=$(base64 -D <<< "${data_b64}" | file -b -)
			case "${dataFileType}" in
				#ensure not just xml and/or valid plist data
				'Apple binary property list'|'XML 1.0 document text'*)
					#decode and convert to XML1
					if ! plistData="$(base64 -D <<< "${data_b64}" | /usr/bin/plutil -convert xml1 - -o - 2>/dev/null)"; then 
						echo "error: pipe used on non-plist data node" >&2
						return 1
					fi
				;;
				*)
					echo "error: pipe used on non-plist data node" >&2
					return 1
				;;
			esac
		fi

		#run query, get data (always ASCII XML)
		if ! queryData=$(plistQuery "${queryArgElement}" <<< "${plistData}"); then 
			if [ -n "${queryArgElement}" ]; then 
				echo "error: key/path not found: ${queryArgElement}" >&2
			fi
			return 1
		else 
			read -r -d '' plistData <<< "${queryData}"
		fi

		#indicate we have looped if we come back around
		let queryLooped++
	done

	#get data type of our resulting plist
	queryDataType=$(getPlistPropertyType <<< "${queryData}")

	case "${myOp}" in
		#-b output queryData as binary plist and return
		'b')
			#output binary plist and return
			plutil -convert binary1 - -o - <<< "${queryData}"
			return 0
		;;
		#crawl the plist and print out paths
		'c'|'C')
			#prints out as it rolls along (if captured in $() can take a long time without visible progress)
			((traverseDataPlist)) && crawlPlist -t "${infoLevel}" <<< "${queryData}" || crawlPlist "${infoLevel}" <<< "${queryData}"
			return 0
		;;
		#convert date to epoch
		'e')
			case "${queryDataType}" in
				"date") outputPlistAsText <<< "${queryData}" | ISO2EPOCH;;
				*) echo "error: option -${myOp} for date type key only"; return 1;;
			esac
			return 0
		;;
		'l')
			#get our answer and exit
			listKeysOrLength <<< "${queryData}" && return 0 || return 1
		;;
		#plist type of key
		't')
			#fix up the output for booleans
			case "${queryDataType}" in true|false) echo "bool";; *) echo "${queryDataType}";; esac
			return 0
		;;
		#print with PlistBuddy
		'p')
			/usr/libexec/PlistBuddy -c "print" /dev/stdin <<< "${queryData}"
			return 0
		;;
		#just xml results formatted with xmllint (more refined than hamfisted plutil formatting)
		'x')
			/usr/bin/xmllint --format - 2>/dev/null <<< "${queryData}"
			return 0
		;;
	esac

	#data type handling (decode,format/process)
	if [ "${queryDataType}" = "data" ]; then 
		#get base64 ascii text from data tag, remove empty lines
		data_b64=$(/usr/bin/xmllint --xpath "/plist/data/text()" - 2>/dev/null <<< "${queryData}")
		#get file type of data
		dataFileType=$(base64 -D <<< "${data_b64}" | file -b -)

		#options handling
		case "${myOp}" in
			#`file` type of decoded data
			'F')
				cat <<< "${dataFileType}"
				return 0
			;;
			#-s option outputs ASCII base64 string
			's')
				#clean up the base64 string remove whitespace
				tr -d $' \r\n\t' <<< "${data_b64}"; echo;
				return 0
			;;
			#json of the base64 encoded data in the key (kinda boring)
			'j')
				#remove whitespace from formatting
				jse <<< $(tr -d $' \r\n\t' <<< "${data_b64}")
				return 0
			;;
			#-r raw output avoid possible processing if plist or JSON data
			'r')
				#raw base64 output and exit
				base64 -D <<< "${data_b64}"
				return 0
			;;
			#any other options (or none)
			*)
				#see if data is plist or not
				case "${dataFileType}" in
					"Apple binary property list"|"XML 1.0 document text"*)
						#if not plist but xml
						if ! output=$(base64 -D <<< "${data_b64}" | /usr/bin/plutil -convert xml1 - -o - 2>/dev/null | xmllint --format - 2>/dev/null); then 
							#format the xml output
							base64 -D <<< "${data_b64}" | xmllint --format - 2>/dev/null
							return 0
						else  
							#pass myOp (only "r" has an effect for raw)
							outputPlistAsText "${myOp}" <<< "${output}"
							return 0
						fi
					;;
					#pretty-print JSON
					"JSON data")
						base64 -D <<< "${data_b64}" | /usr/bin/plutil -convert json -r - -o -; echo;
						return 0
					;;
					#decode and add a newline for output
					"ASCII text, with no line terminators")
						base64 -D <<< "${data_b64}"; echo;
						return 0
					;;
					#anything else output the decoded data
					*)
						base64 -D <<< "${data_b64}"
						return 0
					;;
				esac
			;;
		esac
	#not data type
	else  
		#invalid options if not data type key
		case "${myOp}" in
			'F'|'s')
				echo "error: option -${myOp} for data type key only" >&2
				return 1
			;;
			'j')
				plist2json <<< "${queryData}"
				return 0
			;;
			*)
				#otherwise try and stringify (or output xml)
				#pass myOp (only "r" has an effect)
				outputPlistAsText "${myOp}" <<< "${queryData}"
				return 0
			;;
		esac
	fi
)

#call with all parameters
plb "$@"
