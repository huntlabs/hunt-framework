/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.framework.utils.string;

import std.datetime;
import std.conv;
import std.string;
import std.array;
import std.path;

pragma(inline)
string printDate(DateTime date)
{
    return format("%.3s, %02d %.3s %d %02d:%02d:%02d GMT", // could be UTC too
        to!string(date.dayOfWeek).capitalize, date.day, to!string(date.month)
        .capitalize, date.year, date.hour, date.minute, date.second);
}

/// convert time to RFC822 format string
string toRFC822DateTimeString(SysTime systime)
{
	Appender!string ret;
	
	DateTime dt = cast(DateTime)systime;
	Date date = dt.date;
	
	ret.put(to!string(date.dayOfWeek).capitalize);
	ret.put(", ");
	ret.put(rightJustify(to!string(date.day), 2, '0'));
	ret.put(" ");
	ret.put(to!string(date.month).capitalize);
	ret.put(" ");
	ret.put(to!string(date.year));
	ret.put(" ");
	
	TimeOfDay time = cast(TimeOfDay)systime;
	int tz_offset = cast(int)systime.utcOffset.total!"minutes";
	
	ret.put(rightJustify(to!string(time.hour), 2, '0'));
	ret.put(":");
	ret.put(rightJustify(to!string(time.minute), 2, '0'));
	ret.put(":");
	ret.put(rightJustify(to!string(time.second), 2, '0'));
	
	if (tz_offset == 0)
	{
		ret.put(" GMT");
	}
	else
	{
		ret.put(" " ~ (tz_offset >= 0 ? "+" : "-"));
		
		if (tz_offset < 0) tz_offset = -tz_offset;
		ret.put(rightJustify(to!string(tz_offset / 60), 2, '0'));
		ret.put(rightJustify(to!string(tz_offset % 60), 2, '0'));
	}
	
	return ret.data;
}
	
///mime types
enum MimeTypes = [
	".ez" : "application/andrew-inset", 
	".hqx" : "application/mac-binhex40", 
	".cpt" : "application/mac-compactpro", 
	".doc" : "application/msword", 
	".bin" : "application/octet-stream", 
	".dms" : "application/octet-stream", 
	".lha" : "application/octet-stream", 
	".lzh" : "application/octet-stream", 
	".exe" : "application/octet-stream", 
	".class" : "application/octet-stream", 
	".so" : "application/octet-stream", 
	".dll" : "application/octet-stream", 
	".oda" : "application/oda", 
	".pdf" : "application/pdf", 
	".ai" : "application/postscript", 
	".eps" : "application/postscript", 
	".ps" : "application/postscript", 
	".smi" : "application/smil", 
	".smil" : "application/smil", 
	".wbxml" : "application/vnd.wap.wbxml", 
	".wmlc" : "application/vnd.wap.wmlc", 
	".wmlsc" : "application/vnd.wap.wmlscriptc", 
	".bcpio" : "application/x-bcpio", 
	".vcd" : "application/x-cdlink", 
	".pgn" : "application/x-chess-pgn", 
	".cpio" : "application/x-cpio", 
	".csh" : "application/x-csh", 
	".dcr" : "application/x-director", 
	".dir" : "application/x-director", 
	".dxr" : "application/x-director", 
	".dvi" : "application/x-dvi", 
	".spl" : "application/x-futuresplash", 
	".gtar" : "application/x-gtar", 
	".hdf" : "application/x-hdf", 
	".js" : "application/x-javascript", 
	".skp" : "application/x-koan", 
	".skd" : "application/x-koan", 
	".skt" : "application/x-koan", 
	".skm" : "application/x-koan", 
	".latex" : "application/x-latex", 
	".nc" : "application/x-netcdf", 
	".cdf" : "application/x-netcdf", 
	".sh" : "application/x-sh", 
	".shar" : "application/x-shar", 
	".swf" : "application/x-shockwave-flash", 
	".sit" : "application/x-stuffit", 
	".sv4cpio" : "application/x-sv4cpio", 
	".sv4crc" : "application/x-sv4crc", 
	".tar" : "application/x-tar", 
	".tcl" : "application/x-tcl", 
	".tex" : "application/x-tex", 
	".texinfo" : "application/x-texinfo", 
	".texi" : "application/x-texinfo", 
	".t" : "application/x-troff", 
	".tr" : "application/x-troff", 
	".roff" : "application/x-troff", 
	".man" : "application/x-troff-man", 
	".me" : "application/x-troff-me", 
	".ms" : "application/x-troff-ms", 
	".ustar" : "application/x-ustar", 
	".src" : "application/x-wais-source", 
	".xhtml" : "application/xhtml+xml", 
	".xht" : "application/xhtml+xml", 
	".zip" : "application/zip", 
	".au" : "audio/basic", 
	".snd" : "audio/basic", 
	".mid" : "audio/midi", 
	".midi" : "audio/midi", 
	".kar" : "audio/midi", 
	".mpga" : "audio/mpeg", 
	".mp2" : "audio/mpeg", 
	".mp3" : "audio/mpeg", 
	".aif" : "audio/x-aiff", 
	".aiff" : "audio/x-aiff", 
	".aifc" : "audio/x-aiff", 
	".m3u" : "audio/x-mpegurl", 
	".ram" : "audio/x-pn-realaudio", 
	".rm" : "audio/x-pn-realaudio", 
	".rpm" : "audio/x-pn-realaudio-plugin", 
	".ra" : "audio/x-realaudio", 
	".wav" : "audio/x-wav", 
	".pdb" : "chemical/x-pdb", 
	".xyz" : "chemical/x-xyz", 
	".bmp" : "image/bmp", 
	".gif" : "image/gif", 
	".ief" : "image/ief", 
	".jpeg" : "image/jpeg", 
	".jpg" : "image/jpeg", 
	".jpe" : "image/jpeg", 
	".png" : "image/png", 
	".tiff" : "image/tiff", 
	".tif" : "image/tif", 
	".djvu" : "image/vnd.djvu", 
	".djv" : "image/vnd.djvu", 
	".wbmp" : "image/vnd.wap.wbmp", 
	".ras" : "image/x-cmu-raster", 
	".pnm" : "image/x-portable-anymap", 
	".pbm" : "image/x-portable-bitmap", 
	".pgm" : "image/x-portable-graymap", 
	".ppm" : "image/x-portable-pixmap", 
	".rgb" : "image/x-rgb", 
	".xbm" : "image/x-xbitmap", 
	".xpm" : "image/x-xpixmap", 
	".xwd" : "image/x-windowdump", 
	".igs" : "model/iges", 
	".iges" : "model/iges", 
	".msh" : "model/mesh", 
	".mesh" : "model/mesh", 
	".silo" : "model/mesh", 
	".wrl" : "model/vrml", 
	".vrml" : "model/vrml", 
	".css" : "text/css", 
	".html" : "text/html", 
	".htm" : "text/html", 
	".asc" : "text/plain", 
	".txt" : "text/plain", 
	".rtx" : "text/richtext", 
	".rtf" : "text/rtf", 
	".sgml" : "text/sgml", 
	".sgm" : "text/sgml", 
	".tsv" : "text/tab-seperated-values", 
	".wml" : "text/vnd.wap.wml", 
	".wmls" : "text/vnd.wap.wmlscript", 
	".etx" : "text/x-setext", 
	".xml" : "text/xml", 
	".xsl" : "text/xml", 
	".mpeg" : "video/mpeg", 
	".mpg" : "video/mpeg", 
	".mpe" : "video/mpeg", 
	".qt" : "video/quicktime", 
	".mov" : "video/quicktime", 
	".mxu" : "video/vnd.mpegurl", 
	".avi" : "video/x-msvideo", 
	".movie" : "video/x-sgi-movie", 
	".ice" : "x-conference-xcooltalk" 
];

///get mime content type by extension
string mimeContentType(string ext)
{
	return MimeTypes.get(ext, "application/octet-stream");
}

/// get mime content type by filename
string getMimeContentTypeForFile(string filename)
{
	string ext = extension(filename);

	return mimeContentType(ext);
}

/// merge multiple strings into a long string
string mergeString(string[] params)
{
	Appender!string ret;
	
	foreach(str; params)
	{
		ret.put(str);
	}
	
	return ret.data;
}