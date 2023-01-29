// credit to https://astexplorer.net/ for the amazing interactive AST playground
export const parser = 'babylon'

function transformer(file, api) {
  const j = api.jscodeshift;

  return j(file.source)
    .find(j.ExportDefaultDeclaration)
    .forEach(path => {
    	const className = path.value.declaration.id.name;
    	const source = j(path.value.declaration).toSource();
    	return path.replace(source + `\n\nexport default ${className};`)
    })
    .toSource();
}

export default transformer;

