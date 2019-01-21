require "spec_helper"
describe AJIMS::LTI::OutcomeResponse do

  let(:response_xml) do
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<imsx_POXEnvelopeResponse xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
<imsx_POXHeader>
<imsx_POXResponseHeaderInfo>
<imsx_version>V1.0</imsx_version>
<imsx_messageIdentifier></imsx_messageIdentifier>
<imsx_statusInfo>
<imsx_codeMajor>success</imsx_codeMajor>
<imsx_severity>status</imsx_severity>
<imsx_description/>
<imsx_messageRefIdentifier>123456789</imsx_messageRefIdentifier>
<imsx_operationRefIdentifier>replaceResult</imsx_operationRefIdentifier>
</imsx_statusInfo>
</imsx_POXResponseHeaderInfo>
</imsx_POXHeader>
<imsx_POXBody>
<replaceResultResponse></replaceResultResponse>
</imsx_POXBody>
</imsx_POXEnvelopeResponse>
  XML
  end

  def mock_response(xml)
    @fake = Object
    OAuth::AccessToken.stub(:new).and_return(@fake)
    @fake.should_receive(:code).and_return("200")
    @fake.stub(:body).and_return(xml)
  end

  it "should parse replaceResult response xml" do
    mock_response(response_xml)
    res = AJIMS::LTI::OutcomeResponse.from_post_response(@fake)
    res.success?.should == true
    res.code_major.should == 'success'
    res.severity.should == 'status'
    res.description.should == nil
    res.message_ref_identifier.should == '123456789'
    res.operation.should == 'replaceResult'
    res.score.should == nil
  end

  it "should parse readResult response xml" do
    read_xml = response_xml.gsub('<replaceResultResponse></replaceResultResponse>', <<-XML)
<readResultResponse>
<result>
<resultScore>
<language>en</language>
<textString>0.91</textString>
</resultScore>
</result>
</readResultResponse>
    XML
    read_xml.gsub!('replaceResult', 'readResult')
    mock_response(read_xml)
    res = AJIMS::LTI::OutcomeResponse.from_post_response(@fake)
    res.success?.should == true
    res.code_major.should == 'success'
    res.severity.should == 'status'
    res.description.should == nil
    res.message_ref_identifier.should == '123456789'
    res.operation.should == 'readResult'
    res.score.should == '0.91'
  end

  it "should parse readResult response xml" do
    mock_response(response_xml.gsub('replaceResult', 'deleteResult'))
    res = AJIMS::LTI::OutcomeResponse.from_post_response(@fake)
    res.success?.should == true
    res.code_major.should == 'success'
    res.severity.should == 'status'
    res.description.should == nil
    res.message_ref_identifier.should == '123456789'
    res.operation.should == 'deleteResult'
    res.score.should == nil
  end

  it "should recognize a failure response" do
    mock_response(response_xml.gsub('success', 'failure'))
    res = AJIMS::LTI::OutcomeResponse.from_post_response(@fake)
    res.failure?.should == true
  end

  it "should generate response xml" do
    res = AJIMS::LTI::OutcomeResponse.new
    res.process_xml(response_xml)
    alt = response_xml.gsub("\n",'')
    res.generate_response_xml.should == alt
  end

  describe '#valid' do
    let(:post_response) { double('res') }
    let(:response) { AJIMS::LTI::OutcomeResponse.from_post_response(post_response) }

    before do
      allow(OAuth::AccessToken).to receive(:new).and_return(post_response)
      allow(post_response).to receive(:code).and_return('200')
      allow(post_response).to receive(:body).and_return(response_xml)
    end

    context 'when the response code is 200' do
      context 'when it parses the response as a valid xml' do
        it 'returns true' do
          expect(response).to be_valid
        end
      end

      context 'when it cannot parse the response as a valid xml' do
        let(:response_xml) { '<invalid>xml</document>' }

        it 'returns false' do
          expect(response).not_to be_valid
        end
      end
    end

    context 'when the response code is not 200' do
      before do
        allow(post_response).to receive(:code).and_return('500')
      end

      it 'returns false' do
        expect(response).not_to be_valid
      end
    end
  end
end
