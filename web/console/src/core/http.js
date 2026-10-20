/**
 * Native Window.fetch requires the Window receiver (Safari/WebKit brand-check).
 * Never store an unbound `fetch` reference or call it as `this.fetcher(...)`.
 */
export function browserFetch(input, init) {
  const root = typeof window !== 'undefined' ? window : globalThis;
  if (typeof root.fetch !== 'function') throw Error('No hay cliente HTTP disponible');
  return root.fetch.call(root, input, init);
}

/** Wrap any injectable fetcher so native fetch always keeps the Window receiver. */
export function wrapFetcher(fetcher) {
  if (typeof fetcher !== 'function') throw Error('No hay cliente HTTP disponible');
  return (input, init) => {
    try {
      return fetcher.call(typeof window !== 'undefined' ? window : globalThis, input, init);
    } catch (err) {
      const msg = String(err?.message || err);
      if (/Window\.fetch|Illegal invocation|instances of Window/i.test(msg)) {
        return browserFetch(input, init);
      }
      throw err;
    }
  };
}
