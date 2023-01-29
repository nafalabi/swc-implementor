// credit to https://astexplorer.net/ for the amazing interactive AST playground
export const parser = "babylon";

export default function transformer(file, api) {
    const j = api.jscodeshift;

    return j(file.source)
        .find(j.StringLiteral)
        .forEach((path) => {
            const value = path.value.value;
            if (value !== "babel-loader") return path;
            const babelLoaderNode = path.parentPath.parentPath;
            babelLoaderNode.node.properties.pop();
            path.value.value = "swc-loader";
        })
        .toSource();
}

