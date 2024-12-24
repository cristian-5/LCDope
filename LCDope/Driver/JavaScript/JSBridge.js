
Date.prototype.format = function(format) {
	const components = {
		"YYYY": this.getFullYear(),
		"MM": String(this.getMonth() + 1).padStart(2, '0'),
		"DD": String(this.getDate()).padStart(2, '0'),
		"HH": String(this.getHours()).padStart(2, '0'),
		"mm": String(this.getMinutes()).padStart(2, '0'),
		"ss": String(this.getSeconds()).padStart(2, '0'),
		"SSS": String(this.getMilliseconds()).padStart(3, '0'),
	};
	return format.replace(/YYYY|MM|DD|HH|mm|ss|SSS/g, m => components[m]);
};

class Response {
	
	static statusTexts = {
		100: "Continue",
		101: "Switching Protocols",
		102: "Processing",
		103: "Early Hints",
		200: "OK",
		201: "Created",
		202: "Accepted",
		203: "Non-Authoritative Information",
		204: "No Content",
		205: "Reset Content",
		206: "Partial Content",
		207: "Multi-Status",
		208: "Already Reported",
		226: "IM Used",
		300: "Multiple Choices",
		301: "Moved Permanently",
		302: "Found",
		303: "See Other",
		304: "Not Modified",
		305: "Use Proxy",
		307: "Temporary Redirect",
		308: "Permanent Redirect",
		400: "Bad Request",
		401: "Unauthorized",
		402: "Payment Required",
		403: "Forbidden",
		404: "Not Found",
		405: "Method Not Allowed",
		406: "Not Acceptable",
		407: "Proxy Authentication Required",
		408: "Request Timeout",
		409: "Conflict",
		410: "Gone",
		411: "Length Required",
		412: "Precondition Failed",
		413: "Payload Too Large",
		414: "URI Too Long",
		415: "Unsupported Media Type",
		416: "Range Not Satisfiable",
		417: "Expectation Failed",
		418: "I'm a teapot",
		421: "Misdirected Request",
		422: "Unprocessable Entity",
		423: "Locked",
		424: "Failed Dependency",
		425: "Too Early",
		426: "Upgrade Required",
		428: "Precondition Required",
		429: "Too Many Requests",
		431: "Request Header Fields Too Large",
		451: "Unavailable For Legal Reasons",
		500: "Internal Server Error",
		501: "Not Implemented",
		502: "Bad Gateway",
		503: "Service Unavailable",
		504: "Gateway Timeout",
		505: "HTTP Version Not Supported",
		506: "Variant Also Negotiates",
		507: "Insufficient Storage",
		508: "Loop Detected",
		510: "Not Extended",
		511: "Network Authentication Required"
	};
	
	constructor(body, status, headers, url, redirected = false) {
		this._body = body; // private `#` is not supported
		this.status = status;
		this.statusText = Response.statusTexts[status] || "";
		this.ok = status >= 200 && status < 300;
		this.headers = headers;
		this.url = url;
		this.redirected = redirected;
		this.type = "basic";
	}
	
	text() { return Promise.resolve(this._body); }
	
	json() {
		try { return Promise.resolve(JSON.parse(this._body)); }
		catch (e) { return Promise.reject("Invalid JSON"); }
	}
	
	blob() { return Promise.resolve(new Blob([this._body])); }
	
	arrayBuffer() {
		const buffer = new ArrayBuffer(this._body.length);
		const view = new Uint8Array(buffer);
		for (let i = 0; i < this._body.length; i++)
			view[i] = this._body.charCodeAt(i);
		return Promise.resolve(buffer);
	}
	
	formData() {
		const formData = new FormData();
		const params = new URLSearchParams(this._body);
		for (const [key, value] of params)
			formData.append(key, value);
		return Promise.resolve(formData);
	}
	
	clone() {
		// create a compatible deep-copy of the headers
		// `structuredClone` does not exist in JSContext
		const headers = JSON.parse(JSON.stringify(this.headers));
		return new Response(this._body, this.status, headers, this.url, this.redirected);
	}
	
}

class Headers {
	
	_normalize(key) { return key.toLowerCase(); }
	
	constructor(values = {}) {
		this._values = {}; // private `#` is not supported
		for (const k in values) this.set(k, values[k]);
	}
	
	append(key, value) {
		key = this._normalize(key);
		if (this.has(key)) this._values[key] += `, ${value}`;
		else this._values[key] = value;
	}
	
	delete(key) { delete this._values[this._normalizeName(key)]; }
	
	get(key) { return this._values[this._normalize(key)] || null; }
	set(key, value) { this._values[this._normalize(key)] = value; }
	has(key) { return this._normalize(key) in this._values; }
	
	keys() { return Object.keys(this._values); }
	values() { return Object.values(this._values); }
	entries() { return Object.entries(this._values); }
	
	[Symbol.iterator]() { return this.entries()[Symbol.iterator](); }
	
}

class LocalStorage {
	constructor() { this._storage = new Map(); }
	getItem(key) {
		if (typeof key !== "string") key = key.toString();
		return this._storage.get(key) || null;
	}
	setItem(key, value) {
		if (typeof key !== "string") key = key.toString();
		this._storage.set(key, value);
	}
	removeItem(key) {
		if (typeof key !== "string") key = key.toString();
		this._storage.delete(key);
	}
	clear() { this._storage.clear(); }
	get length() { return this._storage.size; }
	__store() { return [...this._storage]; }
	__load(items) {
		this._storage.clear();
		for (const [key, value] of items)
			this._storage.set(key, value);
	}
}

const localStorage = new LocalStorage();

class Display {
	
	static _CRC32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
	static _FONT_5x7 = [
		 "0000000", // space
		 // ! " # $ % & ' ( ) * + , - . /
		 "4444404", "0AA0000", "00AZAZA", "Y55EMMF", "3K842SR",
		 "699P99P", "4400000", "8444448", "4888884", "A4A0000",
		 "0004E40", "0000042", "0000E00", "0000004", "01248G0",
		 // digits
		 "EHSNKHE", "464444E", "EHGC21Z", "EHGCGHE", "RMJHZGG",
		 "Z1FGGHE", "EH1FHHE", "ZG84222", "EHHEHHE", "EHHYGHE",
		 // : ; < = > ? @
		 "0004040", "0004044", "0084248", "000E0E0", "0024842", "EHG8404", "EHSNS1Y",
		 // A-Z
		 "YHHZHHH", "FHHFHHF", "EH111HE", "FHHHHHF", "Z11F11Z",
		 "Z11F111", "EH11SHE", "HHHZHHH", "E44444E", "RGGGHHE",
		 "H95359H", "111111Z", "HVNHHHH", "HHKNSHH", "EHHHHHE",
		 "FHHF111", "EHHHN9P", "FHHFHHH", "EH1EGHE", "Z444444",
		 "HHHHHHE", "HHHHHA4", "HHHHNNA", "HHA4AHH", "HHA4444", "ZG8421Z",
		 // [ \ ] ^ _ `
		 "E22222E", "0G84210", "E88888E", "04AH000", "000000E", "4800000",
		 // a-z
		 "00CGYJW", "222EJJE", "00CJ2JC", "GGGWJJW", "00CJY2W",
		 "0C2E221", "00CJWGE", "222EJJJ", "0404444", "0808884",
		 "2JA6AJJ", "4444448", "00FNNNN", "00WJJJJ", "00CJJJC",
		 "00CJE22", "00CJWGG", "00T6222", "00W2CGE", "044Y44R",
		 "00JJJJW", "00HHHA4", "00HHHNA", "00JJCJJ", "00JJWGC", "00YGC2Y",
		 // { | } ~ ♥︎
		 "C22122C", "4444444", "688G886", "0002N80", "ZZZZZZZ", "0AZZE40"
	 ];
	 static _FONT_W = 5;
	 static _FONT_H = 7;
	 
	 backlight(color = 0x000000) {
		 if (!["string", "number"].includes(typeof color)) color = 0x000000;
		 __lcd_backlight(color);
	 }
	 pixel(x, y, color = 0xFFFFFF) { __lcd_pixel(x, y, color); }
	 clear(x, y) { __lcd_clear(); }
	 fill(color = 0xFFFFFF) { __lcd_fill(color); }
	 
	 get width() { return __LCD_WIDTH; }
	 get height() { return __LCD_HEIGHT; }
	 get size() { return [__LCD_WIDTH, __LCD_HEIGHT]; }
	 
	 _char_5x7(code, x, y, color) {
		 const B = Display._FONT_5x7[code - 32] || "";
		 if (typeof color === "function") {
			 for (let i = 0; i < B.length; i++)
				 for (let j = 0, t = Display._CRC32.indexOf(B[i]); j < 5; j++, t >>= 1) {
					 const X = x + j, Y = y + i;
					 if (t & 1) __lcd_pixel(X, Y, color(X, Y));
				 }
		 } else {
			 for (let i = 0; i < B.length; i++)
				 for (let j = 0, t = Display._CRC32.indexOf(B[i]); j < 5; j++, t >>= 1)
					if (t & 1) __lcd_pixel(x + j, y + i, color);
		 }
	 }
	 
	 character(c, x = 0, y = 0, color = 0xFFFFFF) {
		 this._char_5x7(c.charCodeAt(0), x, y, color);
	 }
	 
	 print(message, x = 0, y = 0, color = 0xFFFFFF) {
		 if (typeof message !== "string") message = `${message}`;
		 for (let i = 0, r = 0, c = 0; i < message.length; i++) {
			 const code = message.charCodeAt(i);
			 const X = x + c * 6, Y = y + r * 8;
			 const wrap = X + Display._FONT_W > __LCD_WIDTH;
			 if (wrap || code === 13 || code === 10) {
				 r++;
				 c = 0;
				 if (wrap && code > 32) i--; // re-print VALID letter on next line
				 continue;
			 }
			 this._char_5x7(code, X, Y, color);
			 c++;
		 }
	 }

}

const display = new Display();

console.log   = (...M) =>   __log(M.map(m => `${m || "undefined"}`).join(' '));
console.error = (...M) => __error(M.map(m => `${m || "undefined"}`).join(' '));
console.warn  = (...M) =>  __warn(M.map(m => `${m || "undefined"}`).join(' '));
console.info  = (...M) =>  __info(M.map(m => `${m || "undefined"}`).join(' '));
console.debug = (...M) => __debug(M.map(m => `${m || "undefined"}`).join(' '));
console.assert = (condition, ...M) => !condition && __error(M.map(m => `${m}`).join(' '));
console.clear = __clear;

function rgb(r, g, b) {
	if (r % 1 !== 0) r = Math.floor(Math.min(1, Math.max(0, r)) * 255) & 0xFF;
	if (g % 1 !== 0) g = Math.floor(Math.min(1, Math.max(0, g)) * 255) & 0xFF;
	if (b % 1 !== 0) b = Math.floor(Math.min(1, Math.max(0, b)) * 255) & 0xFF;
	return (r << 16) | (g << 8) | b;
}

function hsl(h, s, l) {
	h = Math.min(1, Math.max(0, h)) * 360; // H from 0 to 360
	s = Math.min(1, Math.max(0, s));       // S from 0 to 1
	l = Math.min(1, Math.max(0, l));       // L from 0 to 1
	let c = (1 - Math.abs(2 * l - 1)) * s;
	let x = c * (1 - Math.abs((h / 60) % 2 - 1));
	let m = l - c / 2;
	let r, g, b;
	if (h >= 0 && h < 60)         { r = c; g = x; b = 0; }
	else if (h >=  60 && h < 120) { r = x; g = c; b = 0; }
	else if (h >= 120 && h < 180) { r = 0; g = c; b = x; }
	else if (h >= 180 && h < 240) { r = 0; g = x; b = c; }
	else if (h >= 240 && h < 300) { r = x; g = 0; b = c; }
	else { r = c; g = 0; b = x; }
	r = Math.floor((r + m) * 255);
	g = Math.floor((g + m) * 255);
	b = Math.floor((b + m) * 255);
	return rgb(r, g, b);
}
