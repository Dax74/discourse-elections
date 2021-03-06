import { createWidget } from 'discourse/widgets/widget';
import { ajax } from 'discourse/lib/ajax';
import { h } from 'virtual-dom';

export default createWidget('election-list', {
  tagName: 'div.election-list',
  buildKey: (attrs) => 'election-list',

  defaultState() {
    return {
      elections: [],
      loading: true
    }
  },

  getElections() {
    const category = this.attrs.category;

    if (!category) {
      this.state.loading = false;
      this.scheduleRerender();
      return;
    }

    ajax(`/election/${category.id}`).then((elections) => {
      this.state.elections = elections;
      this.state.loading = false;
      this.scheduleRerender();
    });
  },


  html(attrs, state) {
    const user = this.currentUser;
    const elections = state.elections;
    const loading = state.loading;
    const category = this.attrs.category;
    let contents = [];

    if (loading) {
      this.getElections();
    } else if (elections.length > 0) {
      contents.push(h('span', `${I18n.t('election.list.label')}: `));
      contents.push(h('ul', elections.map((e, i) => {
        let item = [];

        if (i > 0) {
          item.push(h('span', ', '));
        }

        item.push(h('a', { href: e.url }, h('span', e.position)));

        return h('li', item);
      })));
    }

    return contents;
  }
})
