---- Set up DB
--USE PubMedXML
--GO

-- Create table for import
CREATE TABLE PubMedXMLImport (
_ID INT IDENTITY(1,1)
,XMLDump XML
)

-- Import XML
-- Source file is some publications from PubMed, from the journal Structure
INSERT INTO PubMedXMLImport (XMLDump)
SELECT CONVERT(XML,BulkColumn,2)
FROM OPENROWSET(BULK 'C:\Users\Anders\Dropbox\SQL\PubmedArticleSet.xml',SINGLE_CLOB) as X

-- Split to PubmedArticle
SELECT
PubmedArticleSet.PubmedArticle.value('(MedlineCitation/PMID/text())[1]', 'nvarchar(max)') as [PMID]
,PubmedArticleSet.PubmedArticle.query('.') as [X]
into #tmp
FROM PubMedXMLImport
    CROSS APPLY XMLDump.nodes('/PubmedArticleSet/PubmedArticle') as PubmedArticleSet(PubmedArticle)

-- Go through the publications, look for the citations
SELECT
--PubmedArticleSet.PubmedArticle.value('declare namespace example="http://www.pubmed.org/example";(example:abstract/text())[1]', 'nvarchar(max)') as abstract -- If namespaces are encountered
PubmedArticleSet.PubmedArticle.value('(PMID/text())[1]', 'varchar(100)') as [PMID]
,CommentsCorrectionsList.CommentsCorrections.value('(PMID/text())[1]', 'varchar(100)') as Citing
,CommentsCorrectionsList.CommentsCorrections.value('(@RefType)[1]', 'varchar(100)') as ReferenceType
from #tmp
  CROSS APPLY x.nodes('PubmedArticle/MedlineCitation') as PubmedArticleSet(PubmedArticle)
  OUTER apply PubmedArticleSet.PubmedArticle.nodes('CommentsCorrectionsList/CommentsCorrections') as CommentsCorrectionsList(CommentsCorrections)
