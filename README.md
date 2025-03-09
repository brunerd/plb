# plb
plist broker is a command line utility for macOS 13+ 

Related blog articles at: https://www.brunerd.com/blog/tag/plb

```
plb 1.0 - plist broker (https://github.com/brunerd/plb)
A tool for exploring and extracting data within plists

Usage:
 plb [option] [file/domain] [query]

Arguments:
 [file/domain] - Optional (if piped/redirected input), filepath or preference domain name
 [query] - Optional, key name or colon-delimited key path, pipe delimit paths in data encoded plists

Description:
 • plb takes a binary or ascii property list and renders it as either plaintext, XML, or JSON
 • Input can come from file redirection, piped input, filepath or domain name argument
 • Individual values can be extracted using a colon delimited key path (PlistBuddy-style)
   ° Use a pipe character (quoted or escaped) to specify paths within plists encoded as data
 • Data types are decoded and output raw or if plist or JSON data, processed further
 • By default simple types (except data) are output as plaintext
 • Dicts are always output as an XML property list (and not plaintext, unless empty)
 • Arrays are rendered as plaintext only if they do not contain dict or data types
 • Date types remain in native ISO 8601 format, use -e to convert to epoch

Options (pick one):

 Help/Informational:
  -d get user domains, newline delimited from `defaults domains`
  -D get ByHost user domains that match host UUID
  -h this help text
  -f file path of given domain name

 All plist abstract types:
  -b output plist or query results in binary property list format
  -c[cc] Crawl plist or query results with increasing levels of detail (path -> type -> value)
     -c Colon delimited key paths
    -cc Add abscract type of the node delimited with ` >>> `
   -ccc (or -v) Print value of simple types; data types output as plaintext, formatted XML/JSON, or xxd dump
  -C[CC] Crawl plist and also traverse the plists within data keys in increasing detail (path -> type -> value)
     -C Colon delimited key paths; plists in data keys are indentated with pipe (|) delimitation in key paths
    -CC Add abscract type of the node delimited with ` >>> `
   -CCC (or -V) Print value of simple types; data types output as plaintext, formatted XML/JSON, or xxd dump
  -j convert plist or query results to JSON (all types coerced to strings)
  -p print plist or query results using PlistBuddy
  -r raw output; inhibits further processing of XML, plist, or JSON data within string or data types
  -t print abstract type of plist or query results
  -x ensure XML output; inhibits both data type decoding and plaintext output

 Array and Dictionary types (only):
  -l list all keys within a dictionary or print length of an array

 Data types (only):
  -F `file` type of decoded base64 data
  -s plaintext string of base64 encoded data (whitespace removed)

 Date types (only):
  -e output ISO 8601 date in epoch time instead
  
XML property list abstract types:
 Simple/primitive types: string, integer, date, data, real, bool
 Complex/container types: dict, array

References:
  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/AboutPropertyLists/AboutPropertyLists.html
  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/UnderstandXMLPlist/UnderstandXMLPlist.html
  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/Introduction/Introduction.html
  man pages: plist(5), plutil(1), PlistBuddy(8), defaults(1)
  
Examples:

#zsh only, this ignores comment lines if you copy/paste the examples
 set -k

#list all the key names in a pref domain (or specified path)
 plb -l .GlobalPreferences

# plb will decode binary plist data and display as plaintext if possible or XML if not
 plb com.apple.CloudSubscriptionFeatures.cache :ai.apps.image-playground

# You can inhibit decoding of a plists in data types with -x (not so useful)
 plb -x com.apple.CloudSubscriptionFeatures.cache :ai.apps.image-playground

# Add the pipe character and it traverses into the data even with -x or -j for JSON
 plb -x com.apple.CloudSubscriptionFeatures.cache ':ai.apps.image-playground|'
 plb -j com.apple.CloudSubscriptionFeatures.cache ':ai.apps.image-playground|'

# List all key names within plist data
 plb -l com.apple.CloudSubscriptionFeatures.cache ':ai.apps.image-playground|'

# Specify a path within a data plist after a pipe character (quoted or escaped)
 plb com.apple.CloudSubscriptionFeatures.cache ':ai.apps.image-playground|:value:canUse'

# Dates can be output in epoch with -e, otherwise they are ISO 8601
 plb -e com.apple.CloudSubscriptionFeatures.cache ':ai.apps.image-playground|:fetched'

Advanced Examples:

#comma separated list of large preference domains to skip
skipDomains="com.apple.audio.AudioComponentCache,com.apple.SpeakSelection,com.apple.garageband10,com.apple.EmojiCache,com.apple.audio.InfoHelper"

#1 Get key paths and values for all user preferences 
# substitute `plb -D` for ByHost user prefs
IFS=$'\n'; for domain in $(plb -d); do
 #skip large domains
 grep -qE '(^|,)'"${domain}"'(,|$)' <<< "${skipDomains}" && continue
 echo "## Domain: $domain"; echo "## File Path: $(plb -f "${domain}")"; plb -V "${domain}"; echo
done

#2 Get key paths and values for all .plist files in /Library/Preferences
IFS=$'\n'; for domain in $(find /Library/Preferences -type f -name '*plist'); do
 grep -qE "(^|,)${domain}(,|$)" <<< "${skipDomains}" && continue
 echo "## Domain: $domain"; echo "## File Path: $(plb -f "${domain}")"
 # Adjust the info level/output below
 plb -V "${domain}"; echo
done

# Examples 1 & 2 exercises
 # Adjust the info level/output from -V to -CC or -C then try shallower crawls with -cc and -c
 # Output XML with `plb -x`, JSON with `plb -j`; both are speedier than crawling but with tradeoffs
 # `plb -p` prints quickly with PlistBuddy, while key/value pairs are easily spotted, paths are not

#3 Get the `file` type of all data nodes in your user prefs, you might find something interesting
IFS=$'\n'; for domain in $(plb -d); do
 grep -qE "(^|,)${domain}(,|$)" <<< "${skipDomains}" && continue
 echo "## Domain: $domain"
 echo "## Path: $(plb -f "${domain}")"
 #the sed at the end is if you use -CC, its removes the indents from the paths of data embedded plist
 for datapath in $(plb -cc "${domain}" | awk -F ' >>> ' '/data$/ {print $1}' | sed 's/^ *//'); do 
  #get file type of data and key path
  echo "$(plb -F "$domain" "$datapath") <<< ${datapath}"
 done
 echo
done

# Example 3 notes: 
 # `plb -cc` does not go into data plists, use `plb -CC` to search within data plists
 # Use the awk field separator `-F ' >>> '` to easily parse -cc/-CC output ($1 paths, $2 type)

Related blog articles at: https://www.brunerd.com/blog/tag/plb
Source and updates at: https://github.com/brunerd/plb
plx is a smaller more spare version of plb for embedding: https://github.com/brunerd/plx
```
