import os
import sys
sys.path.insert(0, os.path.abspath('..'))

import view393

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.napoleon',
    'sphinx.ext.intersphinx',
    'sphinx.ext.inheritance_diagram',
    'sphinx_autodoc_typehints',
    'sphinx.ext.autosectionlabel',
]

templates_path = ['_templates']

source_suffix = '.rst'

master_doc = 'index'

project = u'View393'
copyright = u'2018, René Kijewski'
author = u'René Kijewski'

with open(os.path.join(os.path.abspath('..'), 'view393', 'VERSION'), 'rt') as f:
    release = eval(f.read())
    version = '.'.join(release.split('.', 2)[:2])


language = None

exclude_patterns = []

pygments_style = 'sphinx'

todo_include_todos = False

html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'navigation_depth': -1,
}
html_sidebars = {
    '**': [
        'localtoc.html',
        'searchbox.html',
    ]
}

htmlhelp_basename = 'View393doc'

display_toc = True
autodoc_default_flags = ['members']
autosummary_generate = True

intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
}

inheritance_graph_attrs = {
    'size': '"6.0, 8.0"',
    'fontsize': 32,
    'bgcolor': 'transparent',
}
inheritance_node_attrs = {
    'color': 'black',
    'fillcolor': 'white',
    'style': '"filled,solid"',
}
inheritance_edge_attrs = {
    'penwidth': 1.2,
    'arrowsize': 0.8,
}
