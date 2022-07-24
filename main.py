from markdown import markdown
from jinja2 import Environment, PackageLoader
from feedgen.feed import FeedGenerator

from datetime import datetime
from base64 import b64encode
import glob
import re
import os
import sys
import shutil

ROOT_URL = 'https://noati.me/'
AUTHOR   = 'noati.me'
CNAME    = 'noati.me'

def gen_posts():
	posts = [(re.split('\\\\|/', x)[1][:-3].title().replace('_', ' '),
			  markdown(open(x, encoding='UTF-8').read()),
			  os.path.getctime(x)
			 )
		for x in sorted(filter(os.path.isfile, glob.iglob('raw/*.md')),
			key=os.path.getctime, reverse=True)]
	
	return posts

def gen_buttons():
	return [f'data:image/gif;base64,{b64encode(open(x, "rb").read()).decode()}' for x in glob.iglob('buttons/*.gif')]

def main():
	try: shutil.rmtree('docs')
	except (FileNotFoundError, PermissionError): pass

	if len(sys.argv) == 2 and sys.argv[1] == 'clean':
		return

	if not os.path.exists('docs'):
		os.mkdir('docs')

	jinja_env = Environment(loader=PackageLoader('main'))
	jinja_env.globals.update({
		'relative': lambda res: f'../../{res}'.replace('//', '/'),
		'strftime': lambda x: datetime.fromtimestamp(x).strftime('%Y-%m-%d')
	})

	posts = gen_posts()

	# CNAME
	if CNAME:
		open('docs/CNAME', 'w').write(CNAME)

	# Index
	buttons = gen_buttons()
	open('docs/index.html', 'w', encoding='UTF-8').write(jinja_env.get_template('index.html').render(title=AUTHOR, posts=posts, buttons=buttons))

	# Other pages
	for filename in glob.iglob('templates/*.html'):
		filename = re.split('\\\\|/', filename)[1]
		foldername = filename.split('.html')[0]
		if filename in ['index.html', 'post.html']:
			continue

		os.makedirs(f'docs/{foldername}', exist_ok=True)
		open(f'docs/{foldername}/index.html', 'w', encoding='UTF-8').write(jinja_env.get_template(filename).render(title=AUTHOR, posts=posts))

	# Posts
	fg = FeedGenerator()
	fg.title('noati.me')
	fg.author(name=AUTHOR)
	fg.link(href=ROOT_URL, rel='alternate')
	fg.link(href=f'{ROOT_URL}/feed.xml', rel='self')
	fg.logo(f'{ROOT_URL}/favicon.png')
	fg.subtitle(ROOT_URL)
	fg.language('en')

	for post in posts:
		path = f'docs/post/{round(post[2])}'

		# Generate HTML
		os.makedirs(path, exist_ok=True)
		open(f'{path}/index.html', 'w', encoding='UTF-8').write(jinja_env.get_template('post.html').render(title=post[0], post=post))

		# Copy images over
		shutil.copytree('raw/img', 'docs/img', dirs_exist_ok=True)

		# Generate RSS
		fe = fg.add_entry()
		fe.id(f'{ROOT_URL}/{path}')
		fe.title(post[0])
		fe.link(href=f'{ROOT_URL}/{path}')
		fe.author(name=AUTHOR)
		fe.content(post[1])
	
	# Write out RSS
	fg.rss_file('docs/feed.xml')


if __name__ == '__main__':
	main()