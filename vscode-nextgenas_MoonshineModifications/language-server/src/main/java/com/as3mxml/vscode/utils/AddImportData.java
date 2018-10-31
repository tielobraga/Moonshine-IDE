/*
Copyright 2016-2018 Bowler Hat LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package com.as3mxml.vscode.utils;

import org.eclipse.lsp4j.Position;

public class AddImportData
{
	public AddImportData(Position position, String indent, String newLines)
	{
		this.position = position;
		this.indent = indent;
		this.newLines = newLines;
	}

	public Position position;
	public String indent;
	public String newLines;
}