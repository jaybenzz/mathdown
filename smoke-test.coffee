sauceConnectLauncher = require('sauce-connect-launcher')
wd = require('wd')
assert = require('assert')
chalk = require('chalk')

sauceUser = process.env.SAUCE_USERNAME || 'mathdown'
# I hope storing this in a public test is OK given that an Open Sauce account
# is free anyway.  Can always revoke if needed...
sauceKey = process.env.SAUCE_ACCESS_KEY || '23056294-abe8-4fe9-8140-df9a59c45c7d'

sauceConnectOptions = {
  username: sauceUser
  accessKey: sauceKey
  verbose: true
  logger: console.log
}

browser = wd.remote('ondemand.saucelabs.com', 80, sauceUser, sauceKey)

browser.on 'status', (info) ->
  console.log(chalk.cyan(info))
browser.on 'command', (meth, path) ->
  console.log(' > %s: %s', chalk.yellow(meth), path)
#browser.on 'http', (meth, path, data) ->
#  console.log(' > %s %s %s', chalk.magenta(meth), path, chalk.grey(data))

desired = {
  browserName: 'internet explorer'
  version: '8'
  platform: 'Windows XP'
  name: 'smoke test'
}

# TODO: Cleanup even if there were errors.  Use promises for sanity?

test = (cb) ->
  # TODO: use current source (via Sauce Connect?)
  browser.get 'http://mathdown.net/?doc=_mathdown_test_smoke', (err) ->
    assert.ifError(err)
    browser.waitFor wd.asserters.jsCondition('document.title.match(/smoke test/)', 2000), (err, value) ->
      assert.ifError(err)
      browser.waitForElementByCss '.MathJax_Display', 15000, (err, el) ->
        assert.ifError(err)
        el.text (err, text) ->
          assert.ifError(err)
          if not text.match(/^\s*α\s*$/)
            assert.fail(text, '/^\s*α\s*$/', 'math text is wrong', ' match ')
          console.log(chalk.green('ALL PASSED'))
          cb()

sauceConnectLauncher sauceConnectOptions, (err, sauceConnectProcess) ->
  assert.ifError(err)
  browser.init desired, (err) ->
    assert.ifError(err)
    test ->
      browser.quit()
      sauceConnectProcess.close ->
        console.log(chalk.green('Cleaned up.'))