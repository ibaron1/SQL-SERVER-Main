SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
-- ==================================================================
-- Author: Eli Baron
-- Create date: 2017-06-09
-- Description: Get items from list
-- ==================================================================
create Function [dbo].[fn_GetItemsFromList]
	(@List Varchar(max), @Delimiter char(1))
Returns @Items table(Item varchar(896), id int identity, primary key nonclustered(Item, id)) --added identity column to guarantee unqueness for PK; otherwise will cause an exception
As
Begin
 Declare @Item Varchar(max), @Pos int
 While Len(@List) > 0 
 Begin
 Set @Pos = CharIndex(@Delimiter, @List)
 If @Pos = 0 Set @Pos = Len(@List) + 1 
 Set @Item = Left(@List, @Pos - 1)
 Insert @Items 
 Select Ltrim(Rtrim(@Item))
 Set @List = 
     SubString(@List, @Pos + case when @Delimiter=' ' then 1 else Len(@Delimiter) end, Len(@List))

 End
 Return
End