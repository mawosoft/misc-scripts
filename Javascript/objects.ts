// Copyright (c) Matthias Wolf, Mawosoft.

/**
 * Returns the name of all owned and inherited properties of the specified object.
 *
 * @remarks
 * This includes properties defined on the prototype chain up to, but not including `Object` itself.
 * Excluded are functions defined as properties, private properties, and static properties.
 */
export function getAllPropertyNames(obj: unknown): string[] {
    if (obj === null || typeof (obj) !== 'object') return [];
    const names = new Set<string>();
    do {
        for (const [k, v] of Object.entries(Object.getOwnPropertyDescriptors(obj))) {
            if (typeof (v.value) !== 'function') names.add(k);
        }
        obj = Object.getPrototypeOf(obj);
    } while (obj && obj.constructor !== Object);
    return [...names];
}

/** Options for {@link normalizedClone} */
export interface NormalizedCloneOptions {
    /**
     * - `'number'` - If safe, coerce to `number`, otherwise to `string`.
     * - `'string'` - Always coerce to `string`.
     * - If undefined, copy original value.
     */
    bigIntCoercion?: 'number' | 'string';
    /**
     * - `'circular'` - Replace circular references with a *JSONPath* string pointing to the first
     *   occurence of the object.
     * - `'all'` - Replace all references with a *JSONPath* string pointing to the first
     *   occurence of the object.
     * - If undefined, do not replace any references with *JSONPath* strings.
     */
    jsonPathReferences?: 'circular' | 'all';
    /**
     * The prefix to use for *JSONPath* strings. Defaults to `'$ref: '`
     */
    referencePrefix?: string;
}

/**
 * Creates a deep copy of the specified value, using mostly simple objects like `Object` and `Array`.
 *
 * @remarks
 * - Primitives are value-copied, even if they are object-wrapped, i.e. a `Number` object becomes a `number`.
 * - `Function` and `Symbol` objects become `undefined`.
 * - A `Date` object is always cloned via the Date constructor, i.e. new Date(originalDate).
 * - Any iterable object will be cloned as an `Array`.
 * - Any other object will be cloned as a simple `Object`, with the owned and inherited properties of the
 *   original assigned to it, regardless whether they are enumerable or not on the original.
 * - Object identities on the clone are the same as on the source, except for unwrapped primitives and
 *   the Date object.
 * - `bigint` values can be optionally coerced to `number` or `string`.
 * - Object references (circular or otherwise) within the structure can optionally be converted to a
 *   *JSONPath* string.
 */
export function normalizedClone(value: unknown, options?: NormalizedCloneOptions): any {
    const seen = new Map<object, ReferenceDescriptor>();
    let ancestors: Map<object, ReferenceDescriptor> | undefined;
    let coerceBigInt: (v: bigint) => bigint | number | string;
    let forceJsonPath = false;
    const referencePrefix = options?.referencePrefix ?? '$ref: ';
    switch (options?.bigIntCoercion?.toLowerCase()) {
        case 'number':
            coerceBigInt = v => v >= Number.MIN_SAFE_INTEGER && v <= Number.MAX_SAFE_INTEGER ? Number(v) : v.toString();
            break;
        case 'string':
            coerceBigInt = v => v.toString();
            break;
        default:
            coerceBigInt = v => v;
            break;
    }
    switch (options?.jsonPathReferences?.toLowerCase()) {
        case 'circular':
            ancestors = new Map();
            break;
        case 'all':
            forceJsonPath = true;
            break;
    }

    return traverse(value, null!, '');

    function traverse(value: unknown, parent: object, propertyKey: string | number): any {
        if (value === null || value === undefined) return value;
        switch (typeof value) {
            case 'object':
                break;
            case 'function':
            case 'symbol':
                return undefined;
            case 'bigint':
                return coerceBigInt(value);
            default: // boolean / number / string
                return value;
        }
        if (value instanceof Boolean || value instanceof Number || value instanceof String) {
            return value.valueOf();
        }
        if (value instanceof BigInt) {
            return coerceBigInt(value.valueOf());
        }
        if (value instanceof Date) {
            return new Date(value);
        }

        if (ancestors) {
            const ancestor = ancestors.get(value);
            if (ancestor) {
                if (typeof ancestor.result !== 'string') {
                    ancestor.result = referencePrefix + toJsonPath(ancestor, ancestors);
                }
                return ancestor.result;
            }
        }

        const descriptor = seen.get(value);
        if (descriptor) {
            if (forceJsonPath && typeof descriptor.result !== 'string') {
                descriptor.result = referencePrefix + toJsonPath(descriptor, seen);;
            }
            return descriptor.result;
        }

        if (typeof (value as any)[Symbol.iterator] === 'function') {
            const result: Array<unknown> = [];
            const descriptor = { key: propertyKey, parent: parent, result: result };
            seen.set(value, descriptor);
            if (ancestors) ancestors.set(value, { ...descriptor });
            let index = 0;
            for (const item of (value as Iterable<unknown>)) {
                const v = traverse(item, value, index);
                result.push(v);
                index++;
            }
            if (ancestors) ancestors.delete(value);
            return result;
        }
        else {
            const result: Record<string, unknown> = {};
            const descriptor = { key: propertyKey, parent: parent, result: result };
            seen.set(value, descriptor);
            if (ancestors) ancestors.set(value, { ...descriptor });
            for (const name of getAllPropertyNames(value)) {
                result[name] = traverse((value as any)[name], value, name);
            }
            if (ancestors) ancestors.delete(value);
            return result;
        }
    }
}

interface ReferenceDescriptor {
    key: string | number;
    parent: object;
    result: object | string;
}

const regexIdStart = /\p{ID_Start}|\$|_/u;
const regexNotIdContinue = /[^\p{ID_Continue}\$]/u;

function toJsonPath(item: ReferenceDescriptor, lookup: Map<object, ReferenceDescriptor>): string {
    let path = '';
    while (item && item.parent) {
        let segment = item.key;
        if (typeof segment == 'number') {
            path = '[' + segment + ']' + path;
        }
        else if (segment.length > 0 && regexIdStart.test(segment.charAt(0)) && !regexNotIdContinue.test(segment.substring(1))) {
            path = '.' + segment + path;
        }
        else {
            path = '[\'' + segment.replaceAll('\'', '\\\'') + '\']' + path;
        }
        item = lookup.get(item.parent)!;
    }
    return '$' + path;
}
