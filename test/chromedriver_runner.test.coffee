chromedriverRunner = require '..'
{expect} = chai = require 'chai'
sinon = require 'sinon'
chai.use require('sinon-chai')
nock = require 'nock'


describe 'chromedriver-runner', ->

  describe '.create', ->
    {chromedriver} = {}

    describe 'with no options', ->
      before ->
        chromedriver = chromedriverRunner.create()

      it 'defaults to port 9515', ->
        expect(chromedriver.port).to.equal 9515
        expect(chromedriver.url).to.equal 'http://localhost:9515'

    describe 'with a custom port', ->
      before ->
        chromedriver = chromedriverRunner.create port: 8888

      it 'sets port to 8888', ->
        expect(chromedriver.port).to.equal 8888
        expect(chromedriver.url).to.equal 'http://localhost:8888'

  describe 'given an instance', ->

    describe '::start', ->
      {chromedriver} = {}

      describe 'with a running chromedriver', ->
        before (done) ->
          nock('http://localhost:9515')
            .get('/status')
            .reply(200, {"sessionId":"","status":0,"value":{"build":{"version":"alpha"},"os":{"arch":"x86_64","name":"Mac OS X","version":"10.9.5"}}})
          chromedriver = chromedriverRunner.create()
          sinon.stub(chromedriver, '_spawn')
          chromedriver.start done

        after ->
          nock.cleanAll()
          chromedriver._spawn.restore()

        it 'does not spawn', ->
          expect(chromedriver._spawn).not.to.have.been.called

      describe 'without a running chromedriver', ->
        before (done) ->
          nock('http://localhost:9515')
            .get('/status')
              .delayConnection(1000)
              .reply(200)
            .get('/status')
              .reply(200, {"sessionId":"","status":0,"value":{"build":{"version":"alpha"},"os":{"arch":"x86_64","name":"Mac OS X","version":"10.9.5"}}})
          chromedriver = chromedriverRunner.create()
          sinon.stub(chromedriver, '_spawn')
          chromedriver.start done

        after ->
          nock.cleanAll()
          chromedriver._spawn.restore()

        it 'spawns a chromedriver', ->
          expect(chromedriver._spawn).to.have.been.calledOnce

