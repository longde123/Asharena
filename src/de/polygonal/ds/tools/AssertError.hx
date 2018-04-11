/*
Copyright (c) 2008-2018 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.ds.tools;

/**
	Thrown to indicate that an assertion failed
**/
class AssertError
{
	public var message:String;
	
	public function new(?message:String, ?info:haxe.PosInfos)
	{
		if (message == null) message = "";
		this.message = message;
		
		var stack = haxe.CallStack.toString(haxe.CallStack.callStack());
		stack = ~/\nCalled from de\.polygonal\.ds\.tools\.AssertError.*$/m.replace(stack, "");
		
		this.message = 'Assertation $message failed in file ${info.fileName}, line ${info.lineNumber}, ${info.className}:: ${info.methodName}\nCall stack:${stack}';
	}
	
	public function toString():String return message;
}