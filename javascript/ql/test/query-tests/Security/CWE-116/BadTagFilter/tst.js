var filters = [
    /<script.*?>.*?<\/script>/i, // NOT OK - doesn't match newlines or `</script >`
    /<script.*?>.*?<\/script>/is, // NOT OK - doesn't match `</script >`
    /<script.*?>.*?<\/script[^>]*>/is, // OK
    /<!--.*-->/is, // NOT OK - misses --!> endings
    /<!--.*--!?>/is, // OK
    /<!--.*--!?>/i, // NOT OK, does not match newlines
    /<script.*?>(.|\s)*?<\/script[^>]*>/i, // NOT OK - doesn't match inside the script tag
    /<script[^>]*?>.*?<\/script[^>]*>/i, // NOT OK - doesn't match newlines inside the content
    /<script(\s|\w|=|")*?>.*?<\/script[^>]*>/is, // NOT OK - does not match single quotes for attribute values
    /<script(\s|\w|=|')*?>.*?<\/script[^>]*>/is, // NOT OK - does not match double quotes for attribute values
    /<script( |\n|\w|=|'|")*?>.*?<\/script[^>]*>/is, // NOT OK - does not match tabs between attributes
    /<script.*?>.*?<\/script[^>]*>/s, // NOT OK - does not match uppercase SCRIPT tags
    /<(script|SCRIPT).*?>.*?<\/(script|SCRIPT)[^>]*>/s, // NOT OK - does not match mixed case script tags
    /<script[^>]*?>[\s\S]*?<\/script.*>/i, // NOT OK - doesn't match newlines in the end tag
    /<script[^>]*?>[\s\S]*?<\/script[^>]*?>/i, // OK
]

doFilters(filters)
