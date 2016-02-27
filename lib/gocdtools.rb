require 'rexml/document'


module GocdTools
  def sanitize(xml_doc)
    xml_doc.delete_element '//agent'
  end  
end
